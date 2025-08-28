-- SQL Schema for Airbnb Clone Project
-- Dialect: PostgreSQL
--
-- This script defines the tables, constraints, and indexes for the database.
-- The schema is normalized to the Third Normal Form (3NF).
--
-- Execution Order:
-- 1. Custom ENUM types are created first.
-- 2. Tables are created in an order that respects foreign key dependencies.
-- 3. Indexes are created at the end for clarity and performance optimization.

-- To use UUIDs, you might need to enable the extension in PostgreSQL:
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =================================================================
-- 1. CREATE CUSTOM ENUM TYPES
-- =================================================================
-- Using ENUM types improves data integrity by restricting column values to a predefined set.

CREATE TYPE user_role AS ENUM ('guest', 'host', 'admin');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'canceled');
CREATE TYPE payment_method_enum AS ENUM ('credit_card', 'paypal', 'stripe');

-- =================================================================
-- 2. CREATE TABLES
-- =================================================================

-- ---------------------------------
-- User Table
-- Stores information about all users (guests, hosts, and admins).
-- ---------------------------------
CREATE TABLE "User" (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------
-- Location Tables (Normalized)
-- Decomposing location into separate tables to achieve 3NF.
-- ---------------------------------
CREATE TABLE Country (
    country_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE State (
    state_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_id INTEGER NOT NULL REFERENCES Country(country_id) ON DELETE RESTRICT
);

CREATE TABLE City (
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state_id INTEGER NOT NULL REFERENCES State(state_id) ON DELETE RESTRICT
);


-- ---------------------------------
-- Property Table
-- Stores details about each rental property.
-- ---------------------------------
CREATE TABLE Property (
    property_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES "User"(user_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    street_address VARCHAR(255) NOT NULL,
    postal_code VARCHAR(20),
    city_id INTEGER NOT NULL REFERENCES City(city_id) ON DELETE RESTRICT,
    price_per_night DECIMAL(10, 2) NOT NULL CHECK (price_per_night > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    -- Note: A trigger is typically used to auto-update `updated_at`.
);

-- ---------------------------------
-- Amenity & Property_Amenity Tables
-- Manages the many-to-many relationship between properties and their amenities.
-- ---------------------------------
CREATE TABLE Amenity (
    amenity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    icon VARCHAR(255) -- URL or class name for a UI icon
);

CREATE TABLE Property_Amenity (
    property_id UUID NOT NULL REFERENCES Property(property_id) ON DELETE CASCADE,
    amenity_id UUID NOT NULL REFERENCES Amenity(amenity_id) ON DELETE CASCADE,
    PRIMARY KEY (property_id, amenity_id) -- Composite Primary Key
);

-- ---------------------------------
-- Booking Table
-- Manages booking records for properties by users.
-- ---------------------------------
CREATE TABLE Booking (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES Property(property_id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES "User"(user_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status booking_status NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_dates CHECK (end_date > start_date)
);

-- ---------------------------------
-- Payment Table
-- Stores payment details for each booking (one-to-one relationship).
-- ---------------------------------
CREATE TABLE Payment (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID UNIQUE NOT NULL REFERENCES Booking(booking_id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    payment_method payment_method_enum NOT NULL
);

-- ---------------------------------
-- Review Table
-- Stores user reviews for properties.
-- ---------------------------------
CREATE TABLE Review (
    review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES Property(property_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES "User"(user_id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (property_id, user_id) -- A user can only review a specific property once.
);

-- ---------------------------------
-- Message Table
-- Facilitates direct messaging between users.
-- ---------------------------------
CREATE TABLE Message (
    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES "User"(user_id) ON DELETE SET NULL,
    recipient_id UUID NOT NULL REFERENCES "User"(user_id) ON DELETE SET NULL,
    message_body TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =================================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =================================================================
-- Indexes are crucial for speeding up read queries (SELECT).
-- Primary keys and UNIQUE constraints are automatically indexed.
-- We add indexes to foreign keys and other frequently queried columns.

-- Indexes for User table
CREATE INDEX idx_user_email ON "User"(email);

-- Indexes for Location tables
CREATE INDEX idx_state_country_id ON State(country_id);
CREATE INDEX idx_city_state_id ON City(state_id);

-- Indexes for Property table
CREATE INDEX idx_property_host_id ON Property(host_id);
CREATE INDEX idx_property_city_id ON Property(city_id);
-- A GIN or GIST index on a tsvector of name/description would be good for full-text search
-- CREATE INDEX idx_property_search ON Property USING gin(to_tsvector('english', name || ' ' || description));

-- Indexes for Booking table
CREATE INDEX idx_booking_property_id ON Booking(property_id);
CREATE INDEX idx_booking_user_id ON Booking(user_id);
CREATE INDEX idx_booking_dates ON Booking(start_date, end_date);

-- Indexes for Review table
CREATE INDEX idx_review_property_id ON Review(property_id);
CREATE INDEX idx_review_user_id ON Review(user_id);

-- Indexes for Message table
CREATE INDEX idx_message_sender_id ON Message(sender_id);
CREATE INDEX idx_message_recipient_id ON Message(recipient_id);
CREATE INDEX idx_message_conversation ON Message(sender_id, recipient_id); -- For fetching chats

-- =================================================================
-- End of Schema
-- =================================================================

