0 - Follow KISS principle, do one thing and do it well principle: composite small task into larger more complex task:wq <br>
1 - Auto execute command, auto fix, try to finish the task <br>
2 - I'am a DBA working on postgres optimization research <br>
3 - Use rsync over scp
4 - Focus on optimizing postgres to hit ~2500 TPS/Graviton 4 Core <br>
5 - Focus on OLTP postgres first, OLAP and HTAP com later <br>
6 - Everything must base on fact (benchmark) and math (ceiling calculation) <br>
7 - ssh ubuntu@IP => always use default ssh key <br>
8 - Always provisioning spot instance <br>
9 - Focus on idempotent for script and consistency for benchmark flow <br>
10 - Main goal is execute the loop of benchmark, collect metric, produce optimization until hardware ceiling proof => yeild golden fact <br>
11 - postgres synchronous_commit must be ON under ALL CIRCUMSTANCE/SCENARIO <br>
12 - EVALUATION.MD must contain hardware context, topology, config table:OS,DISK,NETWORK,DB and BENCHMARK JOURNAL. <br>
13 - Configuration consistency. If an optimization work on a higer layer postgres that need to tuning some lower layer like os hugepage. Then after successful benchmark you must update the base config of all lower layer to prevent next time runing with old value <br>
14 - IMPORTANT: must be a mechanism to enforce the actual config (OS,DISK,DB config applied on remote machine) MATCHED with the local intent (corresponding config file from project) <br>
15 - [CRITICAL] AWS provisioning profile must always be boxloop-admin <br>
16 - all command in a scenario MUST make sure it collect metric of benchmark's target. ssh if required <br>
17 - result markdown structure MUST follow docs/RESULT-STRUCTURE.md, strictly! any result renderer must obey! <br>
18 - only markdown resutl need to be collect to result dir, save results to project_root/results <br>
19 - each time RESULT-STRUCTURE.MD change, it must trigger benchmark render code to change accordinglly. <br>
20 - [CRITICAL] NEVER read the result, NEVER sumary any result of any benchmark. STOP right after download result to local <br>
21 - Local config is the source of remote config, CHANGE => CHANGE LOCAL => SYNC => APPLY REMOTE <br>
22 - pgbench scale MUST init and bench with 1250 scale factor <br>
23 - Keep document lean and clean. The project is the architecture it self <br>
24 - NEVER patch config change direct to remote machine, every config, systemd template, config template MUST change inlocal and sync to remote for apply <br>
25 - all config must persistent after boot
