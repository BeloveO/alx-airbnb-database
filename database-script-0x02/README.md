# Sample Data Population Script

This SQL script is designed to populate the Airbnb clone database with realistic and diverse sample data. The data is themed around locations, users, and properties in several African countries, including **South Africa**, **Nigeria**, and **Kenya**, making it ideal for development, testing, and demonstration purposes.

## What's Included?

The script creates a set of interconnected data that simulates real-world usage:

*   **Diverse Users:** Sample hosts and guests with names common in various African regions.
*   **Realistic Properties:** Listings in major cities like Cape Town, Lagos, and Nairobi, each with unique descriptions.
*   **Booking Scenarios:** A mix of past (completed), future (confirmed), and pending bookings to test different application states.
*   **Linked Data:** A completed booking is linked to a payment record and a detailed review.
*   **User Interaction:** A sample message conversation between a guest and a host regarding an upcoming stay.

## Prerequisites

Before running this script, you must ensure that:

1.  You have a running PostgreSQL database.
2.  The database (e.g., `airbnb_clone_db`) has been created.
3.  The main schema has been created by successfully running the `schema.sql` script.

## How to Use

Execute the script against your database using a command-line tool like `psql`. Make sure to replace `your_user` and `your_db_name` with your actual database credentials.

```bash
psql -U your_user -d your_db_name -a -f seeding_africa.sql
```

## ⚠️ Important Note

This script is designed to be run once on a clean database schema. Running it multiple times will result in duplicate data and may cause errors due to `UNIQUE` constraints. If you need to re-populate the database, it is recommended to drop and recreate the schema first to ensure a clean state.
