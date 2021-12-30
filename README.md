# Spark performance test project.

This project configures the environment and runs the performance tests for Spark+Alluxio+S3 in the CI cluster.

## Pipeline Flow

- #### Setup environment
    This project extends the Staging project, and uses the jobs from Staging to set up services in this environment. In addition, for cold runs, the Alluxio service will first be cleaned up from the performance environment.

    See the [Staging documentation](https://gitlab.planetrover.ca/sequoiadp/qa/staging/-/blob/master/README.md) for more information.

- #### Run Spark Job
    There 5 Spark jobs supported in this project.  
    - JavaWordCount (default): A standard sample spark application included with spark. The collect stage is skipped when running this job.
    - SampleResult: A spark application that writes a delta table and outputs a sample result of a performance benchmark. Used for testing the output parsing script(perfLogParser.sh).
    - RunTPCDS: TPC-DS benchmark.
    - RunTPCHSmallDatePartition: TPC-H SmallDatePartition benchmark.
    - RunTPCHLargeDatePartition: TPC-H LargeDatePartition benchmark.  

    For more information on the benchmarks visit: https://gitlab.planetrover.ca/sequoiadp/spark-sql-perf  

- #### Collect benchmark output
    In this stage, the Alluxio metrics and Spark job output and gathered, parsed and collected into a text file. The parsed file will be outputted as an artifact of the pipeline. When the pipeline finishes, you can head over to CI/CD -> Pipelines and in the collect job for the pipeline that was ran, you will be able to download the text file containing the parsed output on the right side of the page.

- #### Cleanup environment
    Cleanup can be triggered manually by setting the variable `ONLY_CLEANUP` to 'true'. This will clean up ALL services in the environment, as well as the pull secret for docker images. This also has the same effect as clearing the Alluxio cache, so run with caution.

## Running a performance benchmark
To manually trigger run, head over to CI/CD -> Pipelines. On the top right, click "Run pipeline". You will see a page with configurations you can set for the performance run and when ready hit the "Run pipeline" button.

## Performing a "Warm" Run
There are two types of performance runs you can trigger (configurable through the `RUN_CONDITION` variable when triggering the pipeline).  

A "cold" run which is the default type, clears up the environment before running the performance test so Alluxio will be a fresh deployment with nothing cached at the start of the run.  

A "warm" run will perform the performance test ontop of the current environment that is available. For example, if the TPC-H LargeDatePartition benchmark was previously ran and Alluxio has cached all of the data for that benchmark, if the environment was not cleaned up, then performing a warm run of the TPC-H LargeDatePartition benchmark will run the test again but all of the data will already be in Alluxio cache.  
If no deployment of Alluxio is available, Alluxio will be deployed.


## Monitoring Performance Run (Requires access to k8s cluster)
There are a couple areas you can monitor during these performance tests.  
- #### Spark UI
Port-forward to spark-driver pod at port 4040 to view the Spark UI, for e.g.:
```
# Make sure you use the correct namespace
kubectl port-forward --address 0.0.0.0 spark-driver 4040:4040  
```
Then enter localhost:4040 in your browser.  

- #### Alluxio UI
Port-forward to alluxio master pod at port 19999 to view the Alluxio Web UI, for e.g.:
```
# Make sure you use the correct namespace
kubectl port-forward --address 0.0.0.0 alluxio-master-0 8000:19999  
```
Then enter localhost:8000 in your browser.  
For more information about Alluxio UI visit: https://docs.alluxio.io/os/user/stable/en/operation/Web-Interface.html

- #### Spark dashboard
This project also deploys a Grafana dashboard that visualizes important metrics outputted from the Spark job.  
Port-forward to the Grafana service at port 3000 to view the dashboard, for e.g.:
```
# Make sure you use the correct namespace
kubectl port-forward --address 0.0.0.0 service/spark-dashboard-grafana 3000:3000
```
Then enter localhost:3000 in your browser.  
Login with admin:admin  
On the top left of the page click "General / Home" -> Spark_Perf_Dashboard_v03  
For more information about the Spark dashboard visit: https://github.com/cerndb/spark-dashboard

**Currently, the namespace for the performance environment is `performance-47-testing`.**
