# High Usage Columns in the Database tables
Here are the high-usage columns to focus on, based on typical AirBnB-like queries (JOINs on user_id/property_id, filters by status/dates, ORDER BY on names/titles, WHERE on emails/dates):

## 1. Users table

- user_id (PK): used in JOINs to bookings; sometimes in ORDER BY.
- email: frequent WHERE lookups (login/uniqueness).
- last_name, first_name: used in ORDER BY; sometimes filtered (search).
- created_at: filtered or sorted by signup date.
- status/active: filtered to exclude suspended/inactive users.

--- 
## 2. Bookings table

- booking_id (PK): primary key access and sorting in reports.
- user_id (FK): JOIN to users; frequent WHERE filter (user’s bookings).
- property_id (FK): JOIN to properties; frequent WHERE/GROUP BY (per-property stats).
- start_date, end_date: WHERE date-range searches and availability checks; ORDER BY.
- created_at: recent activity feeds, audits; ORDER BY.
- status: WHERE filters (confirmed/cancelled/completed).
- price_total or nightly_rate (if present): reporting/filtering.

---
## 3. Properties table

- property_id (PK): JOIN to bookings and reviews; sometimes ORDER BY.
- title: used in ORDER BY/search results.
- host_id (FK to users): JOINs for host dashboards.
- city_id/location fields (city, state, country or geohash): frequent WHERE filters.
- price/nightly_rate: filtered/sorted in search.
- bedrooms/capacity/property_type: faceted filters.
- created_at: newest listings sort/filter.
- active/status: WHERE to hide inactive/unlisted.

---
## Indexing tips (to improve performance)

- Ensure all PKs and FKs are indexed:
  - bookings(user_id), bookings(property_id)
  - properties(host_id), properties(city_id)
  - users(email) UNIQUE
- Common composites:
  - bookings(property_id, start_date) for availability and per-property ranges.
  - bookings(user_id, start_date DESC) for user booking history.
  - bookings(property_id, created_at DESC) for recent bookings per property.
  - users(last_name, first_name) if you sort/filter by names often.
  - properties(city_id, price) for search filtering; properties(active, city_id) if you filter by active first.
- ORDER BY alone rarely benefits from an index unless paired with a selective WHERE or the index fully covers the query.
- Avoid over-indexing; monitor actual query plans and add indexes where they reduce cost.
