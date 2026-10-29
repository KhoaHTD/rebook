package com.rebook.file;

import com.rebook.support.IntegrationTest;
import com.rebook.user.Role;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class FileUploadTest extends IntegrationTest {

    private static final byte[] PNG = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3};

    @Test
    void uploadedImageCanBeReadBackWithoutLogin() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin", 0);
        var file = new MockMultipartFile("file", "bien-lai.png", "image/png", PNG);

        String body = mvc.perform(multipart("/files").file(file).with(as(admin, Role.ADMIN)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.url").value(org.hamcrest.Matchers.startsWith("/files/")))
                .andReturn().getResponse().getContentAsString();
        String url = body.replaceAll(".*\"url\":\"([^\"]+)\".*", "$1");

        byte[] served = mvc.perform(get(url))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/png"))
                .andReturn().getResponse().getContentAsByteArray();
        assertThat(served).isEqualTo(PNG);
    }

    @Test
    void nonImageIsRejected() throws Exception {
        long admin = createUser(Role.ADMIN, "Admin", 0);
        var file = new MockMultipartFile("file", "x.html", "text/html", "<script>alert(1)</script>".getBytes());

        mvc.perform(multipart("/files").file(file).with(as(admin, Role.ADMIN)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("INVALID_FILE"));
    }

    @Test
    void uploadNeedsLogin() throws Exception {
        var file = new MockMultipartFile("file", "a.png", "image/png", PNG);
        mvc.perform(multipart("/files").file(file)).andExpect(status().isUnauthorized());
    }

    @Test
    void pathTraversalIsNotFound() throws Exception {
        mvc.perform(get("/files/..%2F..%2Fpom.xml")).andExpect(status().is4xxClientError());
        mvc.perform(get("/files/pom.xml")).andExpect(status().isNotFound());
        mvc.perform(get("/files/missing.png")).andExpect(status().isNotFound());
    }
}
