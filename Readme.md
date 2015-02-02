Benchmark of my threadsafe-let-block branch of RSpec::Core

See https://github.com/rspec/rspec-core/pull/1858 for details.

Setting depth to 7 (size increases factorially, so higher than this becomes quite painful)
generates a specfile 4.4M large, with 13.7k examples and 82.2k let statements,
each calling super as many as 7 times. Average time difference is 0.6s

```
== Stats ==
Depth:             7
Normal:            2.766277
Threadsafe:        3.240309
Difference:        0.4740319999999998
$ du -h 7_spec.rb
4.4M 7_spec.rb
$ wc -l 7_spec.rb
  123301 7_spec.rb
$ grep -c example 7_spec.rb
13700
$ grep -c let 7_spec.rb
82203


Average on master:     2.6295119090909096
Average on threadsafe: 3.2429119090909087
Difference:            0.6133999999999991
```
