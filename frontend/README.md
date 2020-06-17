# Frontend Helm Chart

This chart is used to deploy a frontend application, typically as a decoupled frontend.

# Available environment variables

Service containers have following environment variables:
  - Variables defined in silta.yml `php.env`
  - PORT: TCP port local service is running on. This is taken from silta.yml `service.customservice.port`;
  - ENVIRONMENT_DOMAIN: Pre-generated domain name of current deployment (without protocol prefix);
  - RELEASE_NAME: Normalised and trimmed branch name (i.e. `dependabot-npm-and-yarn-apollo-serv-e6b3`);
  - *_HOST: Server host addresses of all services in current deployment, including port. (i.e. `dependabot-npm-and-yarn-apollo-serv-e6b3-node:3000`).
  - When Elasticsearch is enabled:
    - ELASTICSEARCH_HOST: Elasticsearch server host.
  - When RabbitMQ is enabled:
    - RABBITMQ_HOST: RabbitMQ server host.
