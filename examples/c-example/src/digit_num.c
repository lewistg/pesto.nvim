#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "digit_num.h"

static inline bool is_digit_char(unsigned char c) {
  return c >= '0' && c <= '9';
}

struct aoc_digit_num *aoc_make_digit_num(char *num_str) {
  if (num_str == NULL) {
    return NULL;
  }

  size_t len = strlen(num_str);

  struct aoc_digit_num *num;
  num = malloc(sizeof(*num) + len * sizeof(unsigned char));
  if (num == NULL) {
    return NULL;
  }

  for (size_t i = 0; i < len; i++) {
    unsigned digit_char = num_str[i];
    assert(is_digit_char(digit_char));
    num->digits[i] = digit_char - '0';
  }

  num->len = len;

  return num;
}

static unsigned long ul_pow(unsigned long long base, unsigned int pow) {
  unsigned long long product = 1;
  for (size_t i = 0; i < pow; i++) {
    product *= base;
  }
  return product;
}

unsigned long aoc_digit_num_to_unsigned_long(const struct aoc_digit_num *num) {
  unsigned long y = 0;
  for (size_t i = 0; i < num->len; i++) {
    y += num->digits[i] * ul_pow(10, num->len - 1 - i);
  }
  return y;
}

struct aoc_digit_num *aoc_make_digit_from_ten_pow(unsigned int pow) {
  size_t len = pow + 1;
  struct aoc_digit_num *num;
  num = malloc(sizeof(*num) + len * sizeof(unsigned char));
  if (num == NULL) {
    return NULL;
  }
  memset(num->digits, 0, len * sizeof(unsigned char));
  num->len = len;
  num->digits[0] = 1;
  return num;
}

struct aoc_digit_num *aoc_copy_digit_num(const struct aoc_digit_num *num) {
  if (num == NULL || num->digits == NULL) {
    return NULL;
  }

  struct aoc_digit_num *copy;
  size_t total_size = sizeof(*copy) + num->len * sizeof(unsigned char);
  copy = malloc(total_size);
  if (copy == NULL) {
    return NULL;
  }

  memcpy(copy->digits, num->digits, num->len * sizeof(unsigned char));
  copy->len = num->len;

  return copy;
}

void aoc_destroy_digit_num(struct aoc_digit_num *num) { free(num); }

int aoc_compare_digit_nums(const struct aoc_digit_num *x,
                           const struct aoc_digit_num *y) {
  if (x->len < y->len) {
    return -1;
  } else if (x->len > y->len) {
    return 1;
  }

  for (size_t i = 0; i < x->len && i < y->len; i++) {
    if (x->digits[i] != y->digits[i]) {
      return x->digits[i] - y->digits[i] < 0 ? -1 : 1;
    }
  }
  return 0;
}

void aoc_print_digit_num(const struct aoc_digit_num *num) {
  for (size_t i = 0; i < num->len; i++) {
    printf("%c", num->digits[i] + '0');
  }
  printf("\n");
}

char *aoc_digit_num_to_string(const struct aoc_digit_num *num) {
  if (num->len == 0) {
    return NULL;
  }
  char *str = malloc(num->len + 1);
  if (str == NULL) {
    return NULL;
  }
  for (size_t i = 0; i < num->len; i++) {
    str[i] = '0' + num->digits[i];
  }
  str[num->len] = '\0';
  return str;
}
