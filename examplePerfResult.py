
from pyspark.sql import SparkSession
from pyspark.conf import SparkConf
from pyspark.context import SparkContext

if __name__ == "__main__":
    """
        Usage: pi [partitions]
    """

    spark = SparkSession\
        .builder\
        .appName("examplePerfResultApp")\
        .getOrCreate()

    f = open("/builds/sequoiadp/performance/exampleResult.txt", "r")
    print(f.read())
    spark.stop()

