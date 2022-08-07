## Trc - Totally Reliable Code TM

This app uses RabbitMQ to publish/consume datasets that after being parsed, they are stored into a MySQL database.

You can access the dataset entries by sending a `POST` request to the `localhost:4000/api/datasets` endpoint. The data can be paginated and filtered by topic.

To do that, you must pass the dataset name as a query string variable (`dataset`). More information on how to use the API below. 

The data retrieved by the API comes from a Redis cache, that is populated on the first request. 

My focus was to consume the data asynchronously and as fast as possible.

- Created by: Rafael Antunes.

## How Trc works

Once the app starts, a bootstraping process will begin.

The bootstraping process starts by adding the configured Datasets to the `datasets` table and starts a Consumer for each one of them. The Consumers will only start after receiving a message sent by the `Publisher`.

My approach assumes that data is not going to be injected on a regular basis, because of that, the datasets must be defined in the `config.exs` file under the `datasets` key to be stored and consumed. They can also only be populated once. For future improvements, my main goal is to expand this scenario.

After bootstraping, the app will run the `Trc.Publisher.start_streaming` function, this will create a Task for each dataset, this Task streams, parses and stores their respective files. You can only stream a dataset once.

The `Consumer` will store the data into the `dataset_entries` table. As soon as the first request hits the API, the data will also be stored on the Redis Cache. All the subsequents requests will retrieve data only from the cache.

## Considerations about my implementation

- Why did I not use auto increment ID for the dataset entries:
  * This could've been a considerable bottleneck, because each insert request would need to first hit the database to fetch its ID, return to the application, so it can be used by the app. I decided to use the `DateTime` / `timestamp` with microseconds as the ID to avoid this problem.

- How the pagination system works:
  * I decided not to use a limit offset pagination because the latency/response time would increase considerably when used with a higher offset. With that in mind, I made the decision to use the `where` clause as the limit.
  * The where clause is based on the last timestamp received by the frontend. This is a model similar to the infinite scrolling multiple popular apps use, such as: Instagram and TikTok. Where the client gets the first page without a timestamp, and when the client makes the second request, it will fetch the last timestamp received from the last request and passes it to the backend. The backend will return the next entries based on the last one the user has received.

- Why did I not use a FK on the dataset table to link it to its entries?
  * As my focus with this app is performance, I decided not to use a FK to increase the insert time. Not to mention that this also ensures data integrity.
  * This is not a problem because I am already validating the dataset on the Application layer when the app inserts it.

- How RabbitMQ connection works across the consumers:
  * Each consumer when instantiated has it own AMQP connection instead of having a shared connection with all the consumers or a connection pool with shared among the cluser.
  * This can increase the app performance because if the consumers shared a connection, all the inserts would need to be serialized on that connection, possibly becoming a bottleneck. I chose to use a dedicated connection to prevent that from happening even though it uses more memory. 

## How to run the application

- `docker-compouse up --build`
- The API will listen to port `4000` and will serve `/api/datasets` endpoint.

## How to run unit tests

- use `mix test`

## How to use the API

- `POST`: `localhost:4000/api/datasets`
  * Mandatory query string params:
    - `datasets` (filters the data by topic name, this must match one of the datasets names you configured in the `config.exs` file)
  
  * Optional query string params:
    - `limit` (limits the amount of entries that are going to be returned by the API)
    - `last_ts` (you can send the `last_timestamp` value from the last entry returned to go to the next page)

## Future Improvements

- Streaming idempotence:
  * If you run the `start_streaming` function multiple times, it will insert the same entries, even if they are already stored. My idea for a future improvement is to add a verification, where it would verify if an entry has already been stored.
  * Another thing to be improved is that, if the `start_streaming` for some reason stops while it is still running, we would also need to re-insert the data that was stored before it stopped running instead of inserting only the data that has not been stored.
  * For another future improvement related to streaming, I am considering adding a protection against any HTTP requests that comes before the streaming has ended. This would prevent the cache from being wrongly populated and also prevent wrong data from being returned.

- Cache is populated based on the amount of rows:
  * On this current version, the Redis cache is populated based on the amount of rows (limit) requested by the user. If a user gets a page with 50 entries and another one comes in and requests a page with 49 entries, both of them will hit the database. The expected behaviour would be, the first one hits the database and the other one hits the cache. For now, the cache would be hit if the second user also requested a page with 50 entries.

## Troubleshooting 

- MySQL docker is not running:
  * Please check the image on the `docker-compose-yaml` file, if you are a M1 user, you must modify it.