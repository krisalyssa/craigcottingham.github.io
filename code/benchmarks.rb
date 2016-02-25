#!/usr/bin/env ruby -wKU

# Released to the public domain by Craig S. Cottingham on 2011-03-12.

def next_hailstone(n)
  ((n % 2) == 0) ? (n / 2) : ((3 * n) + 1)
end

list = []

(0...10_000_000).each { | i |
  list << i
}

#  10_000_000 => 13255
# 100_000_000 => 35655
5.times do
  
  max = n = 13255
  while (n != 1) do
    val = list.slice! n
    ((n % 2) == 0) ? list.push(val) : list.unshift(val)
    n = next_hailstone n
    # max = ((n > max) ? n : max)
    # throw max if (max > list.size)
  end
  list.reverse!

end
