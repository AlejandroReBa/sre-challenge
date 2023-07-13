import Redis from "ioredis";

export default class RedisClient {
  private static instance: Redis;

  private constructor() {
    // Private constructor to prevent instantiation
  }

  public static getInstance(): Redis {
    if (!RedisClient.instance) {
      RedisClient.instance = new Redis({
        host: process.env.REDIS_HOST,
        port: parseInt(process.env.REDIS_PORT || "6379"),
        username: process.env.REDIS_USERNAME,
        password: process.env.REDIS_PASSWORD,
      });

      // Add error event handler to handle connection errors
      RedisClient.instance.on("error", (error) => {
        console.error(error);
      });
    }
    return RedisClient.instance;
  }
}
