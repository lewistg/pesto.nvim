#ifndef _DIGIT_NUM_H_
#define _DIGIT_NUM_H_

/**
 * An unsigned integer implemented as a list of digits.
 */
struct aoc_digit_num {
  size_t len;
  unsigned char digits[];
};

struct aoc_digit_num *aoc_make_digit_num(char *num_str);

struct aoc_digit_num *aoc_make_digit_from_ten_pow(unsigned int pow);

struct aoc_digit_num *aoc_copy_digit_num(const struct aoc_digit_num *num);

void aoc_destroy_digit_num(struct aoc_digit_num *num);

/**
 * @return -1, 0, 1, when a is respetively less than, equal to, or greater than
 * b
 */
int aoc_compare_digit_nums(const struct aoc_digit_num *a,
                           const struct aoc_digit_num *b);

char *aoc_digit_num_to_string(const struct aoc_digit_num *num);

unsigned long aoc_digit_num_to_unsigned_long(const struct aoc_digit_num *num);

#endif
