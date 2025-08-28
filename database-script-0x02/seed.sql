-- =================================================================
-- SQL SCRIPT TO POPULATE THE AIRBNB CLONE DATABASE WITH SAMPLE DATA
-- =================================================================
-- This script should be run AFTER `schema.sql` has been executed.
-- It inserts data in an order that respects foreign key constraints.

-- Using BEGIN/COMMIT to make the entire script transactional.
BEGIN;

-- =================================================================
-- 1. POPULATE INDEPENDENT TABLES
-- =================================================================

-- ---------------------------------
-- Users (2 hosts, 2 guests, 1 admin)
-- ---------------------------------
INSERT INTO "User" (first_name, last_name, email, password_hash, phone_number, role) VALUES
('Adebayo', 'Adekunle', 'adebayo.a@example.com', 'hashed_password_placeholder_1', '+27-82-111-2222', 'host'),
('Fatima', 'Zahra', 'fatima.z@example.com', 'hashed_password_placeholder_2', '+212-61-333-4444', 'host'),
('Imani', 'Kariuki', 'imani.k@example.com', 'hashed_password_placeholder_3', '+254-72-555-6666', 'guest'),
('Kofi', 'Mensah', 'kofi.m@example.com', 'hashed_password_placeholder_4', '+233-24-777-8888', 'guest'),  
('Admin', 'User', 'admin@example.com', 'hashed_password_placeholder_5', null, 'admin');

-- ---------------------------------
-- Amenities
-- ---------------------------------
INSERT INTO Amenity (name, icon) VALUES
('WiFi', 'wifi-icon'),
('Pool', 'pool-icon'),
('Kitchen', 'kitchen-icon'),
('Free Parking', 'parking-icon'),
('Air Conditioning', 'ac-icon'),
('Hot Tub', 'hottub-icon');

-- ---------------------------------
-- Locations (Country, State/Province/Region, City)
-- ---------------------------------
INSERT INTO Country (name) VALUES ('South Africa'), ('Kenya'), ('Nigeria');

INSERT INTO State (name, country_id) VALUES
('Western Cape', (SELECT country_id FROM Country WHERE name = 'South Africa')),
('Nairobi County', (SELECT country_id FROM Country WHERE name = 'Kenya')),
('Marrakech-Safi', (SELECT country_id FROM Country WHERE name = 'Morocco'));

INSERT INTO City (name, state_id) VALUES
('Cape Town', (SELECT state_id FROM State WHERE name = 'Western Cape')),
('Nairobi', (SELECT state_id FROM State WHERE name = 'Nairobi County')),
('Lagos', (SELECT state_id FROM State WHERE name = 'Ikeja'));

-- =================================================================
-- 2. POPULATE DEPENDENT TABLES
-- =================================================================

-- ---------------------------------
-- Properties
-- ---------------------------------
INSERT INTO Property (host_id, name, description, street_address, postal_code, city_id, price_per_night) VALUES
(
    (SELECT user_id FROM "User" WHERE email = 'adebayo.a@example.com'),
    'Stunning Sea Point Apt with Mountain View',
    'Modern apartment with breathtaking views of Table Mountain and the Atlantic Ocean. Close to the V&A Waterfront.',
    '15 Signal Hill Rd',
    '8001',
    (SELECT city_id FROM City WHERE name = 'Cape Town'),
    120.00
),
(
    (SELECT user_id FROM "User" WHERE email = 'fatima.z@example.com'),
    'Authentic Riad in the Medina',
    'Experience true Moroccan hospitality in this beautifully restored Riad with a central courtyard pool. Steps away from Airport.',
    '12 Bode Thomas, Ikeja',
    '40000',
    (SELECT city_id FROM City WHERE name = 'Lagos'),
    95.50
),
(
    (SELECT user_id FROM "User" WHERE email = 'adebayo.a@example.com'),
    'Chic Urban Flat in Kilimani, Nairobi',
    'A stylish and secure apartment in the vibrant Kilimani neighborhood. Perfect for business travelers or tourists exploring Nairobi.',
    '25 Ngong Rd',
    '00100',
    (SELECT city_id FROM City WHERE name = 'Nairobi'),
    80.75
);

-- ---------------------------------
-- Link Properties with Amenities (Property_Amenity)
-- ---------------------------------
-- Cape Town Apartment Amenities
INSERT INTO Property_Amenity (property_id, amenity_id) VALUES
((SELECT property_id FROM Property WHERE name LIKE 'Stunning Sea Point%'), (SELECT amenity_id FROM Amenity WHERE name = 'WiFi')),
((SELECT property_id FROM Property WHERE name LIKE 'Stunning Sea Point%'), (SELECT amenity_id FROM Amenity WHERE name = 'Kitchen')),
((SELECT property_id FROM Property WHERE name LIKE 'Stunning Sea Point%'), (SELECT amenity_id FROM Amenity WHERE name = 'Free Parking')),
((SELECT property_id FROM Property WHERE name LIKE 'Stunning Sea Point%'), (SELECT amenity_id FROM Amenity WHERE name = 'Air Conditioning'));

-- Lagos Riad Amenities
INSERT INTO Property_Amenity (property_id, amenity_id) VALUES
((SELECT property_id FROM Property WHERE name LIKE 'Authentic Riad%'), (SELECT amenity_id FROM Amenity WHERE name = 'WiFi')),
((SELECT property_id FROM Property WHERE name LIKE 'Authentic Riad%'), (SELECT amenity_id FROM Amenity WHERE name = 'Pool')),
((SELECT property_id FROM Property WHERE name LIKE 'Authentic Riad%'), (SELECT amenity_id FROM Amenity WHERE name = 'Kitchen'));

-- Nairobi Flat Amenities
INSERT INTO Property_Amenity (property_id, amenity_id) VALUES
((SELECT property_id FROM Property WHERE name LIKE 'Chic Urban Flat%'), (SELECT amenity_id FROM Amenity WHERE name = 'WiFi')),
((SELECT property_id FROM Property WHERE name LIKE 'Chic Urban Flat%'), (SELECT amenity_id FROM Amenity WHERE name = 'Kitchen')),
((SELECT property_id FROM Property WHERE name LIKE 'Chic Urban Flat%'), (SELECT amenity_id FROM Amenity WHERE name = 'Air Conditioning'));


-- =================================================================
-- 3. CREATE BOOKINGS, PAYMENTS, REVIEWS, AND MESSAGES
-- =================================================================

-- ---------------------------------
-- Booking Scenario 1: A completed past booking for Imani, which she has reviewed.
-- ---------------------------------
INSERT INTO Booking (property_id, user_id, start_date, end_date, total_price, status) VALUES
(
    (SELECT property_id FROM Property WHERE name LIKE 'Stunning Sea Point%'),
    (SELECT user_id FROM "User" WHERE email = 'imani.k@example.com'),
    '2023-11-10',
    '2023-11-15',
    600.00,  -- 5 nights * 120.00
    'confirmed'
);
-- Payment for this past booking
INSERT INTO Payment (booking_id, amount, payment_method) VALUES
(
    (SELECT booking_id FROM Booking WHERE start_date = '2023-11-10'),
    600.00,
    'stripe'
);
-- Review for this past booking
INSERT INTO Review (property_id, user_id, rating, comment) VALUES
(
    (SELECT property_id FROM Property WHERE name LIKE 'Stunning Sea Point%'),
    (SELECT user_id FROM "User" WHERE email = 'imani.k@example.com'),
    5,
    'The views of Table Mountain were breathtaking! Adebayo was a gracious host and the apartment was spotless. A perfect base for exploring Cape Town.'
);

-- ---------------------------------
-- Booking Scenario 2: A future confirmed booking for Kofi.
-- ---------------------------------
INSERT INTO Booking (property_id, user_id, start_date, end_date, total_price, status) VALUES
(
    (SELECT property_id FROM Property WHERE name LIKE 'Authentic Riad%'),
    (SELECT user_id FROM "User" WHERE email = 'kofi.m@example.com'),
    (CURRENT_DATE + INTERVAL '30 day'),
    (CURRENT_DATE + INTERVAL '34 day'),
    382.00, -- 4 nights * 95.50
    'confirmed'
);
-- Payment for this confirmed booking
INSERT INTO Payment (booking_id, amount, payment_method) VALUES
(
    (SELECT booking_id FROM Booking WHERE status = 'confirmed' AND user_id = (SELECT user_id FROM "User" WHERE email = 'kofi.m@example.com')),
    382.00,
    'paypal'
);

-- ---------------------------------
-- Booking Scenario 3: A pending booking request from Imani for the Nairobi flat.
-- ---------------------------------
INSERT INTO Booking (property_id, user_id, start_date, end_date, total_price, status) VALUES
(
    (SELECT property_id FROM Property WHERE name LIKE 'Chic Urban Flat%'),
    (SELECT user_id FROM "User" WHERE email = 'imani.k@example.com'),
    (CURRENT_DATE + INTERVAL '50 day'),
    (CURRENT_DATE + INTERVAL '53 day'),
    242.25, -- 3 nights * 80.75
    'pending'
);

-- ---------------------------------
-- Messages (A conversation between Kofi and Fatima about his upcoming Marrakech booking)
-- ---------------------------------
INSERT INTO Message (sender_id, recipient_id, message_body) VALUES
(
    (SELECT user_id FROM "User" WHERE email = 'kofi.m@example.com'), -- from Kofi
    (SELECT user_id FROM "User" WHERE email = 'fatima.z@example.com'), -- to Fatima
    'Salam Fatima, I am so excited for my trip! My flight arrives late at night. Will it be difficult to find the Riad in Ikeja?'
);

-- Simulating a small delay for the reply
INSERT INTO Message (sender_id, recipient_id, message_body, sent_at) VALUES
(
    (SELECT user_id FROM "User" WHERE email = 'fatima.z@example.com'), -- from Fatima
    (SELECT user_id FROM "User" WHERE email = 'kofi.m@example.com'), -- to Kofi
    'Wa alaikum assalam Kofi! Do not worry at all. We can arrange a trusted taxi to pick you up from the airport and bring you directly to our door. Welcome to Lagos!',
    (NOW() + INTERVAL '10 minute')
);

-- =================================================================
-- SCRIPT COMPLETE
-- =================================================================
COMMIT;
