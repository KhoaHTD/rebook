package com.rebook.file;

import org.junit.jupiter.api.Test;

import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class CloudinaryStorageTest {

    @Test
    void parsesCloudinaryUrl() {
        var c = CloudinaryStorage.parse("cloudinary://123456:abcSecret@my-cloud");
        assertThat(c).isNotNull();
        assertThat(c.apiKey()).isEqualTo("123456");
        assertThat(c.apiSecret()).isEqualTo("abcSecret");
        assertThat(c.cloudName()).isEqualTo("my-cloud");
    }

    @Test
    void emptyOrPlaceholderMeansDisabled() {
        assertThat(CloudinaryStorage.parse("")).isNull();
        assertThat(CloudinaryStorage.parse(null)).isNull();
        assertThat(CloudinaryStorage.parse("cloudinary://<your_api_key>:<your_api_secret>@dppc2tng8")).isNull();
        assertThat(CloudinaryStorage.parse("http://x:y@z")).isNull();
        assertThat(CloudinaryStorage.parse("cloudinary://onlykey@cloud")).isNull();
    }

    @Test
    void enabledOnlyWithRealCredentials() {
        assertThat(new CloudinaryStorage("", "rebook").enabled()).isFalse();
        assertThat(new CloudinaryStorage("cloudinary://k:s@c", "rebook").enabled()).isTrue();
    }

    @Test
    void signatureIsSha1OfSortedParamsPlusSecret() {
        String sig = CloudinaryStorage.sign(Map.of("timestamp", "1315060510", "folder", "rebook"), "secret");
        assertThat(sig).matches("[0-9a-f]{40}");
        // Thứ tự khoá đưa vào không ảnh hưởng.
        var reversed = new LinkedHashMap<String, String>();
        reversed.put("folder", "rebook");
        reversed.put("timestamp", "1315060510");
        assertThat(CloudinaryStorage.sign(reversed, "secret")).isEqualTo(sig);
        assertThat(CloudinaryStorage.sign(reversed, "other")).isNotEqualTo(sig);
    }
}
