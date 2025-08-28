# Requirements file

## Entities and Attributes

### User:

- **user_id:** Primary Key, UUID, Indexed
- **first_name:** VARCHAR, NOT NULL
- **last_name:** VARCHAR, NOT NULL
- **email:** VARCHAR, UNIQUE, NOT NULL
- **password_hash:** VARCHAR, NOT NULL
- **phone_number:** VARCHAR, NULL
- **role:** ENUM (guest, host, admin), NOT NULL
- **created_at:** TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

### Property

- **property_id:** Primary Key, UUID, Indexed
- **host_id:** Foreign Key, references User(user_id)
- **name:** VARCHAR, NOT NULL
- **description:** TEXT, NOT NULL
- **location:** VARCHAR, NOT NULL
- **pricepernight:** DECIMAL, NOT NULL
- **created_at:** TIMESTAMP, DEFAULT CURRENT_TIMESTAMP
- **updated_at:** TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP

### Booking

- **booking_id:** Primary Key, UUID, Indexed
- **property_id:** Foreign Key, references Property(property_id)
- **user_id:** Foreign Key, references User(user_id)
- **start_date:** DATE, NOT NULL
- **end_date:** DATE, NOT NULL
- **total_price:** DECIMAL, NOT NULL
- **status:** ENUM (pending, confirmed, canceled), NOT NULL
- **created_at:** TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

### Payment

- **payment_id:** Primary Key, UUID, Indexed
- **booking_id:** Foreign Key, references Booking(booking_id)
- **amount:** DECIMAL, NOT NULL
- **payment_date:** TIMESTAMP, DEFAULT CURRENT_TIMESTAMP
- **payment_method:** ENUM (credit_card, paypal, stripe), NOT NULL

### Review

- **review_id:** Primary Key, UUID, Indexed
- **property_id:** Foreign Key, references Property(property_id)
- **user_id:** Foreign Key, references User(user_id)
- **rating:** INTEGER, CHECK: rating >= 1 AND rating <= 5, NOT NULL
- **comment:** TEXT, NOT NULL
- **created_at:** TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

### Message

- **message_id:** Primary Key, UUID, Indexed
- **sender_id:** Foreign Key, references User(user_id)
- **recipient_id:** Foreign Key, references User(user_id)
- **message_body:** TEXT, NOT NULL
- **sent_at:** TIMESTAMP, DEFAULT CURRENT_TIMESTAMP

---

## Relationship between Entities

- ### User & Property:
  A User (with the host role) can own multiple Properties. Each Property is owned by exactly one User. This is a one-to-many relationship. (User 1 -- * Property)

- ### User & Booking:
  A User (as a guest) can make multiple Bookings. Each Booking is made by a single User. This is a one-to-many relationship. (User 1 -- * Booking)

- ### Property & Booking:
  A Property can have many Bookings over time. Each Booking is for a single Property. This is a one-to-many relationship. (Property 1 -- * Booking)

- ### Booking & Payment:
  Each Booking has one corresponding Payment. This is a one-to-one relationship. (Booking 1 -- 1 Payment)

- ### User & Review:
  A User can write many Reviews. Each Review is written by a single User. This is a one-to-many relationship. (User 1 -- * Review)

- ### Property & Review:
  A Property can have many Reviews. Each Review is about a single Property. This is a one-to-many relationship. (Property 1 -- * Review)

- ### User & Message (Self-Referencing):
  The Message table connects to the User table twice. A User can be the sender of many messages, and a User can be the recipient of many messages. This models a direct messaging system between users.

  - User 1 -- * Message (via sender_id)
  - User 1 -- * Message (via recipient_id)

---

## ER Diagram

<img width="2933" height="3840" alt="Untitled diagram | Mermaid Chart-2025-08-28-065926" src="https://github.com/user-attachments/assets/3a3170cf-34fc-4768-8ea5-cc3f0c875199" />
