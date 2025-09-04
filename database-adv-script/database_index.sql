-- -----------------------------
-- Recommended indexes for User table
-- -----------------------------

CREATE UNIQUE INDEX ux_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_login ON users(last_login);
CREATE INDEX idx_users_phone ON users(phone_number);


-- -----------------------------
-- Recommended indexes for Booking table
-- -----------------------------

CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_property_id ON bookings(property_id);
CREATE INDEX idx_bookings_status ON bookings(booking_status);
CREATE INDEX idx_bookings_check_in ON bookings(check_in_date);
CREATE INDEX idx_bookings_check_out ON bookings(check_out_date);
CREATE INDEX idx_bookings_booking_date ON bookings(booking_date);
CREATE INDEX idx_bookings_payment_status ON bookings(payment_status);

-- Composite indexes for common query patterns
CREATE INDEX idx_bookings_user_date ON bookings(user_id, booking_date);
CREATE INDEX idx_bookings_property_date ON bookings(property_id, check_in_date);
CREATE INDEX idx_bookings_date_status ON bookings(booking_date, booking_status);


-- -----------------------------
-- Recommended indexes for Property table
-- -----------------------------

CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_country ON properties(country);
CREATE INDEX idx_properties_property_type ON properties(property_type);
CREATE INDEX idx_properties_price ON properties(price_per_night);
CREATE INDEX idx_properties_bedrooms ON properties(bedrooms);
CREATE INDEX idx_properties_rating ON properties(rating);
CREATE INDEX idx_properties_host_id ON properties(host_id);
CREATE INDEX idx_properties_availability ON properties(is_available);

-- Composite indexes for search functionality
CREATE INDEX idx_properties_location_search ON properties(city, property_type, price_per_night);
CREATE INDEX idx_properties_advanced_search ON properties(city, bedrooms, rating, is_available);
