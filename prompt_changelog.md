This file describes the prompts used in chatgpt to implement this project

## Requirement analysis
the following text describes the goal and requirements for an application that should be implemented in elixir liveview:

Hier was the task description in PDF

can you please do the following?
- summarize the goal of the application
- summarize the requirements in bullet points
- analyze the requirements and let me know any conflicts or any details that might be needed to implement the application
- give me a list of opportunities for improvement

## Answer Requirement Analysis with own assessment
I took the answer from the tool, took some decisions and added other parts I found important 

### ✅ **Goal of the Application**

To create a **real-time rostering system** using **Elixir LiveView** that allows **managers to schedule and assign shifts** to **qualified workers** based on **work type**, **availability**, and **department**, while giving **workers control over their availability** and **visibility into their upcoming shifts**.

---

### 📋 **Requirements Summary**

#### Core Functionalities

- **Shifts**
    - Managers can create shifts.
    - A shift includes:
        - Start time
        - End time
        - Short description
        - Work type (e.g., “Cleaning”, “Security”)
    - Only one person can be assigned per shift.
    - Shifts can span hours to several days.
    - Shifts can be assigned directly or left open for workers to claim.
    - **Shifts should have a state so that more complex logic can be implemented later on. For now just open, assigned**

- **Workers**
    - Can view their assigned shifts.
    - Can define their availability by excluding certain days of the week.
    - Availability defaults to "available all days" if none is set.
    - Can only be assigned to shifts that match:
        - Their **work type qualification**
        - Their **availability**
        - The **department** they belong to

- **Managers**
    - Can assign shifts to workers or themselves.
    - Can create shifts without assigning them (workers can claim them later).
    - Can only assign workers to shifts that match the worker's qualifications, availability, and department.
    - Cannot modify worker availability.
    - Can see all shifts and assign workers accordingly.

- **Departments**
    - A company can have multiple departments (e.g., “Maintenance”, “Customer Support”).
    - Shifts are created against specific departments.
    - Workers can belong to multiple departments.
    - Workers can only be assigned to shifts in departments they belong to.

- **Real-time Interaction**
    - Any updates (shift assignments, availability changes) should reflect immediately to all relevant users (LiveView updates).


**Additional requirements and decisions by me**:
- Availability should have a start/end time and recurring: boolean
- shift claiming by first come first serve
- specify better the role design in the software?
- availability cannot change after a shift is taken and overlaps
- timestamps stored in UTC but taken and shown from the frontend with the local time
- build the UI mobile friendly so that it can seen in tablets and phones

OFI (opportunity for improvement):
- shift and availability can be full week or only working days
- shift approval by manager
- ordered list for work type matching
- improve work type by adding experience and create/match shifts by this criteria
- overlapping shifts for overlapping roles
- mandatory rest time between shifts
- match score for shifts and user skills
- **Shift Templates**: Let managers save templates for commonly used shifts.
- **Calendar Integration**: Integrate with Google Calendar or iCal to visualize shifts.
- **Notifications**: Add email or in-app notifications when shifts are assigned, claimed, or updated.
- **Shift Swapping**: Allow workers to propose shift swaps with other qualified coworkers.
- **Mobile Optimization**: Ensure mobile-friendly UX for on-the-go scheduling.
- **Bulk Shift Creation**: Tools for managers to create recurring or batch shifts quickly.
- **Audit Logs**: Track who made changes to shifts or availability for transparency.
- **Reporting**: Dashboards for shift coverage, worker utilization, department performance, etc.

## Feature Planning
I would like to reset the goal and requirements and that we start building this project together feature by feature.
Here is the goal and the requirements
...input from last step...

Absolutely. With your goal and feature set clearly defined, the best path forward is an incremental full-stack roadmap, where each feature is delivered end-to-end (data → business logic → UI → tests) so we always have a working version.

Here’s a detailed feature roadmap broken into logical phases:

### 🚀 Phase 1: Foundation Setup
🔧 Goals:
- Project scaffold (Phoenix LiveView)
- Base schemas (User, Department, WorkType)
- Role-based user design
- Admin login screen (optional)

✅ Tasks:
- mix phx.new roster_app --live
- Create User schema with roles: [:manager, :worker]
- Add Department, WorkType schemas
- Assign users to departments and work types (UserDepartment, UserQualification)
- Build basic layout and navigation
- Seed data for testing

### 📅 Phase 2: Shift Management (Manager View)
🔧 Goals:
- Managers can create, view, and assign shifts.
- Shifts validated against availability, work type, and department.

✅ Tasks:
- Create Shift schema (start/end time, description, department, work type, assigned_user_id)
- Form to create new shifts (manager view)
- Table/list of shifts with filters (status, department, etc.)
- Dropdown to assign eligible workers

Validate all assignment constraints
- Real-time update on shift creation/assignment (LiveView)


### 👩‍🔧 Phase 3: Worker Availability (Worker View)
🔧 Goals:
- Workers can manage their recurring availability (by weekday, time, recurring)
- Shifts can’t be assigned if they conflict with availability

✅ Tasks:
- Create Availability schema
- Form for setting recurring unavailability (e.g. "no Mondays 8–17")
- Automatic fallback: full availability if none is set
- Manager-side logic: prevent assignment to unavailable workers
- LiveView update when availability changes

### ✋ Phase 4: Shift Claiming & Conflict Handling
🔧 Goals:
- Workers can claim open shifts
- Prevent conflicts with other shifts or availability
- Respect "first come, first served"

✅ Tasks:
- Public list of eligible open shifts (worker dashboard)
- “Claim” button with real-time update
- Conflict checking (overlap, availability)
- Lock to prevent race condition (maybe with Ecto transactions or FOR UPDATE)
- Tests for edge cases (overlapping, simultaneous claims)

### 🧱 Phase 5: Role & Access Management
🔧 Goals:
- Define and enforce user roles cleanly across LiveViews and backend
- Only managers can create or assign shifts

✅ Tasks:
- Plug-based auth enforcement (:manager guard for certain routes)
- UI changes based on role (e.g. no “Assign” if not manager)
- Session-based login system or token auth (if needed)

### 🛠 Phase 6: Real-Time LiveView Interactions
🔧 Goals:
- Ensure all views reflect updates in real-time
- Availability, shift claiming, and assignments push changes instantly

✅ Tasks:
- LiveView presence or PubSub for real-time sync
- Broadcast shifts and availabilities
- UI auto-refresh when shift is claimed/updated
- Mobile-friendly UI with Tailwind or other responsive styling

### 🌱 Phase 7: Availability Exceptions (Non-Recurring)
🔧 Goals:
Let workers say “I’m off on June 10th” even if they usually work Mondays

✅ Tasks:
- Add availability_exceptions schema
- Consider priority of exception over recurring availability
- UI to add/delete specific date exceptions
- Respect these during shift assignment/claim


### 📈 Phase 8: Reporting & Admin Tools
🔧 Goals:
- Dashboards for managers (coverage, hours)
- Audit logs for transparency
- Bulk shift creation

✅ Tasks:
- Analytics: total hours, coverage by department, unfilled shifts
- Create audit tables and log who made updates
- Shift templates and bulk copy tools 

### 🧠 Phase 9+: Advanced Features (Stretch Goals)

Feature	Description
- 🔁 Shift Swapping	Workers propose swaps, managers approve
- 📨 Notifications	Email/in-app notifications
- 📅 Calendar Integration	Google/iCal support
- ⏱ Rest Rules	Enforce rest time between shifts
- 💯 Match Score	Smarter assignment using experience or rating
- 📱 Mobile-first UI	Use Tailwind + LiveView for responsive UI
- 🛣️ Recommended Development Flow


Pick one full feature (e.g. “Manager creates shift”)

- Implement schema + changesets
- Add context functions + validations
- Build LiveView + UI components
- Write tests (unit + LiveView interaction)
- Deploy to a staging server (if applicable)

Would you like to begin with Phase 1, and I’ll walk you through the Mix commands, migrations, and setup?

