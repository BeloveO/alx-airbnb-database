# Database Normalization Analysis

This document reviews the provided database schema for the Airbnb clone project, analyzes its normalization, and suggests adjustments to ensure it adheres to the Third Normal Form (3NF).

## Analysis of the Original Schema
Overall, the initial schema is very well-designed and largely adheres to normalization principles. Let's review each table.

| Table |	1NF Status |	2NF Status	| 3NF Status	| Comments |
|-------|------------|--------------|-------------|----------|
| User	| ✅ Pass	| ✅ Pass	| ✅ Pass	| All attributes depend directly on user_id. There are no transitive dependencies.
| Property| 	✅ Pass	| ✅ Pass |	⚠️ Potential Violation |	The location field is a single VARCHAR. While atomic, it likely contains structured data (e.g., street, city, state, country, zip). This creates a transitive dependency. For example, the country depends on the city, which depends on the location string, not directly on the property_id.
| Booking	| ✅ Pass	| ✅ Pass	| ⚠️ Potential Violation (Calculated Value)	| The total_price attribute is derived from Property.pricepernight and the duration (end_date - start_date). Storing calculated values is a form of redundancy and violates strict 3NF. However, this is often a deliberate and acceptable denormalization for business reasons (e.g., to record the price at the time of booking).
| Payment	| ✅ Pass	| ✅ Pass	| ✅ Pass	| All attributes depend on payment_id. The amount is tied to the specific payment transaction.
| Review	| ✅ Pass	| ✅ Pass	| ✅ Pass	| All attributes depend directly on review_id. No issues.
| Message	| ✅ Pass	| ✅ Pass	| ✅ Pass	| All attributes depend directly on message_id. No issues.

---

## Key Findings

- **Transitive Dependency in Property Table:** The location column is the primary violation of 3NF. Storing a full address as a single string can lead to data inconsistency and makes querying by city or country difficult and inefficient. For example, users might enter "USA", "United States", or "U.S.A.", representing the same country.
- **Deliberate Denormalization in Booking Table:** The total_price field is a calculated value. In a strictly normalized database, you would calculate this on the fly. However, storing it is crucial for creating a historical record of the transaction. If the property's pricepernight changes in the future, past booking records should remain unaffected. We will keep this but acknowledge it as a conscious design choice.
- **Missing Entity for Amenities:** The initial schema did not include amenities. In a real Airbnb clone, properties have amenities (Wi-Fi, Pool, Kitchen, etc.). If we were to add a simple amenities TEXT field to the Property table, it would violate 1NF (a list of values in one column). Even if added as a separate table, its design must be correct. \
🔶 This is a missing feature, not a violation of the given schema. We will add it correctly.

---

## Adjusting the Schema to Achieve 3NF

### Step 1: Create New Location-Related Tables for structured location data (Country, State, and City)

**Country Table:**
- country_id: Primary Key, SERIAL
- name: VARCHAR, UNIQUE, NOT NULL

**State Table:**
- state_id: Primary Key, SERIAL
- name: VARCHAR, NOT NULL
- country_id: Foreign Key, references Country(country_id)

**City Table:**
- city_id: Primary Key, SERIAL
- name: VARCHAR, NOT NULL
- state_id: Foreign Key, references State(state_id)

### Step 2: Modify the Property Table
We remove the generic location column and replace it with a more structured address and a foreign key pointing to the City table.

**Updated Property Table:**

- property_id: Primary Key, UUID
- host_id: Foreign Key, references User(user_id)
- name: VARCHAR, NOT NULL
- description: TEXT, NOT NULL
- street_address: VARCHAR, NOT NULL
- postal_code: VARCHAR, NULL
- city_id: Foreign Key, references City(city_id)
- pricepernight: DECIMAL, NOT NULL
- created_at: TIMESTAMP
- updated_at: TIMESTAMP

This change ensures that street_address and postal_code are directly dependent on the property_id. The city, state, and country information is no longer dependent on a non-key attribute within the Property table but is correctly linked via foreign keys.

### Step 3: New Amenity Properties addition

**New Amenity table:**
- amenity_id: UUID, PRIMARY KEY, Indexed
- name: VARCHAR, UNIQUE, NOT NULL
- icon: VARCHAR, NULL (for UI)

**PROPERTY_AMENITY Junction Table (Added for Completeness):**
- property_id: UUID,	FOREIGN KEY, REFERENCES Property(property_id), PRIMARY KEY(property_id, amenity_id)
- amenity_id:	UUID,	FOREIGN KEY, REFERENCES Amenity(amenity_id), PRIMARY KEY(property_id, amenity_id)

---

## Final 3NF Schema and Visual Representation

<img width="3097" height="3840" alt="Untitled diagram | Mermaid Chart-2025-08-28-075622" src="https://github.com/user-attachments/assets/9528a7e9-fe36-4481-ac6c-b1d36bd5dd7e" />

