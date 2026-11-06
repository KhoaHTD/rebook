package com.rebook.common;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class IsbnTest {

    @Test
    void normalizesHyphensAndConvertsIsbn10To13() {
        assertThat(Isbn.normalize("978-0-306-40615-7")).isEqualTo("9780306406157");
        assertThat(Isbn.normalize("0-306-40615-2")).isEqualTo("9780306406157");
        assertThat(Isbn.normalize("080442957X")).isEqualTo("9780804429573");
        assertThat(Isbn.normalize("080442957x")).isEqualTo("9780804429573");
        assertThat(Isbn.normalize("  ")).isNull();
        assertThat(Isbn.normalize(null)).isNull();
    }

    @Test
    void rejectsWrongCheckDigitOrPrefix() {
        for (String bad : new String[]{"9780306406158", "0306406151", "0000000001", "1234567890123", "12345"}) {
            assertThatThrownBy(() -> Isbn.normalize(bad)).as(bad).isInstanceOf(ApiException.class);
        }
        assertThat(Isbn.toIsbn13("Dế Mèn")).isNull();
    }
}
