# Use the official Postgres image as the base image
FROM postgres:latest

# Install the Postgres client
RUN apt-get update && apt-get install -y postgresql-client && apt-get clean

# Expose the default Postgres port
EXPOSE 5432

# Set the default command to run Postgres
CMD ["postgres"]