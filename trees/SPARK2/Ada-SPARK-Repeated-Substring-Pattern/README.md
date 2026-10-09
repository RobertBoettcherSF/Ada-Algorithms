# Ada-SPARK-Repeated-Substring-Pattern

Repeated substring pattern: is the text some shorter unit repeated two or more times? Works on any `Text_Array` (any lower bound, length up to `Max_Length`); the Post states the result as "some proper divisor P of the length is a period of the text", proved at the folder's level (mode all, level 2). `make test` compares against a brute-force rebuild-and-compare reference on every text over {a,b} up to length 12 and {a,b,c} up to length 8, plus 20,000 seeded random texts (seed 20261009).
