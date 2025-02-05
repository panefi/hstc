# HSTC - Interstellar Route Planner API

This project contains AWS Lambda functions for the HSTC Interstellar Route Planner API. The API enables route planning between various interstellar gates, providing functionality to find the cheapest routes and calculate transportation costs proposing the vehicle type (Personal or HSTC vehicle). It also retrieves the gates and their details.

## Assumptions
- When calculating the cost and proposing the vehicle type, we suggest to the passengers to use the HSTC vehicle, if the cost of the HSTC vehicle is equal to the cost of the Personal vehicle.
- Given the requiremnts for optimal path search, the Dijkstra's Algorithm is well-suited for finding the shortest path in a graph. It efficiently calculates the minimum cost from the departure gate to all other gates.
- The /transport/{distance}?passengers={number}&parking={days} endpoint calculates the cost for the first part of the trip to the gate, and returns the cheapest vehicle to use and the cost of the journey for the given distance (in AUs), number or passengers and days of parking (i.e. vehicle storage at the gate).

## Important Notes
- A separate documentation on how to set up the AWS infrastructure, run the terraform file, and open the Swagger UI is provided.

## Future Improvements
- Add CI/CD pipeline to deploy automatically to AWS when a change is pushed to the branch.
- Set GitFlow workflow for the development process.
- Add unit tests for all lambda functions.
- Add integration tests.

## Instructions to run the project locally

Before you begin, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started)
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- Python 3.13
- MySQL database (local or remote)

## Setup Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <repository-name>
   ```

2. Configure your environment:
   - Copy `sample_env.json` to `env.json`:
     ```bash
     cp sample_env.json env.json
     ```
   - Update `env.json` with your database credentials and configuration:
     ```json
     {
       "GetGatesFunction": {
         "DB_HOST": "your_host",
         "DB_PORT": "your_port",
         "DB_NAME": "your_db_name",
         "DB_USER": "your_username",
         "DB_PASSWORD": "your_password"
       },
       "GetGateByCodeFunction": {
         "DB_HOST": "your_host",
         "DB_PORT": "your_port",
         "DB_NAME": "your_db_name",
         "DB_USER": "your_username",
         "DB_PASSWORD": "your_password"
       },
       "FindCheapestRouteFunction": {
         "DB_HOST": "your_host",
         "DB_PORT": "your_port",
         "DB_NAME": "your_db_name",
         "DB_USER": "your_username",
         "DB_PASSWORD": "your_password"
       },
       "CalculateCostFunction": {
         "DB_HOST": "your_host",
         "DB_PORT": "your_port",
         "DB_NAME": "your_db_name",
         "DB_USER": "your_username",
         "DB_PASSWORD": "your_password"
       }
     }
     ```

3. Update the database parameters in `template.yaml`:
   - Open `template.yaml`
   - Locate the Parameters section at the top
   - Replace the default values with your actual database configuration:
     ```yaml
     Parameters:
       DB_HOST:
         Type: String
         Default: localhost  # Your database host
       DB_PORT:
         Type: String
         Default: 3306      # Your database port
       DB_NAME:
         Type: String
         Default: hstc_db   # Your database name
       DB_USER:
         Type: String
         Default: your_user # Your database user
       DB_PASSWORD:
         Type: String
         Default: your_pass # Your database password
     ```

4. Build and run the API locally:
   ```bash
   sam build && sam local start-api --env-vars env.json
   ```

## Available Endpoints

Once the API is running, you can access the following endpoints at `http://localhost:3000`:

### 1. Get All Gates
- **Endpoint:** `GET /gates`
- **Description:** Retrieves a list of all gates with their details
- **Example:**
  ```bash
  curl --location 'http://127.0.0.1:3000/gates/'
  ```

### 2. Get Gate by Code
- **Endpoint:** `GET /gates/{gateCode}`
- **Description:** Retrieves details for a specific gate
- **Example:**
  ```bash
  curl --location 'http://127.0.0.1:3000/gates/SOL'
  ```

### 3. Find Cheapest Route
- **Endpoint:** `GET /gates/{gateCode}/to/{targetGateCode}`
- **Description:** Determines the cheapest route between two gates
- **Example:**
  ```bash
  curl --location 'http://127.0.0.1:3000/gates/SOL/to/ALD'
  ```

### 4. Calculate Transport Cost
- **Endpoint:** `GET /transport/{distance}`
- **Parameters:**
  - `distance`: Path parameter (required)
  - `passengers`: Query parameter (required)
  - `parking`: Query parameter (required)
- **Example:**
  ```bash
  curl --location 'http://127.0.0.1:3000/transport/100?passengers=2&parking=2'
  ```

## Project Structure

```
├── layers/
│   ├── common_code/    # Common utilities layer
│   └── third_party/    # Third-party dependencies layer
├── lambdas/
│   ├── get_cheapest_route/
│   ├── get_gate_by_code/
│   ├── get_gates/
│   └── get_vehicle_and_cost/
├── swagger.yaml       # Swagger definition
├── template.yaml       # SAM template
├── env.json           # Environment variables (not in repo)
├── uploadTerraform.sh # Script to create the zip files
├── build/             # Build directory with zip files (not in repo)
└── README.md