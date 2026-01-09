1 - prepared vs simple statement produce huge diferrent results
2 - PGPASSWORD=postgres pgbench -h 10.0.1.20 -p 6432 -U postgres bench -c 150 -j 4 -T 300 -P 5
3 - 64k read_ahead_kb best for random access, 4096 best for sequential
4 - TPC-B for raw throughput, TPC-C for real-world OLTP pattern
