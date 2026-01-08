0 - Follow KISS principle
1 - Auto execute command, auto fix, try to finish the task
2 - I'am a DBA working on postgres optimization research
3 - use rsync over scp
4 - Focus on optimizing postgres to hit ~2500 TPS/Graviton 4 Core
5 - Focus on OLTP postgres first, OLAP and HTAP com later
6 - Everything must base on fact (benchmark) and math (ceiling calculation)
7 - ssh ubuntu@IP => always use default ssh key
8 - Always provisioning spot instance
9 - Focus on idempotent for script and consistency for benchmark flow
10 - Main goal is execute the loop of benchmark, collect metric, produce optimization until hardware ceiling proof => yeild golden fact
11 - postgres synchronous_commit must be ON under ALL CIRCUMSTANCE/SCENARIO
12 - EVALUATION.MD must contain hardware context, topology, config table:OS,DISK,NETWORK,DB and BENCHMARK JOURNAL.
13 - Configuration consistency. If an optimization work on a higer layer postgres that need to tuning some lower layer like os hugepage. Then after successful benchmark you must update the base config of all lower layer to prevent next time runing with old value
14 - IMPORTANT: must be a mechanism to enforce the actual config (OS,DISK,DB config applied on remote machine) MATCHED with the local intent (corresponding config file from project)
15 - [CRITICAL] AWS provisioning profile must always be boxloop-admin
16 - all command in a scenario MUST make sure it collect metric of benchmark's target. ssh if required
17 - result markdown structure MUST follow docs/RESULT-STRUCTURE.md, strictly! any result renderer must obey!
18 - only markdown resutl need to be collect to result dir
19 - each time RESULT-STRUCTURE.MD change, it must trigger benchmark render code to change accordinglly.
20 - [CRITICAL] NEVER read the result, NEVER sumary any result of any benchmark. STOP right after download result to local
21 - Local config is the source of remote config
