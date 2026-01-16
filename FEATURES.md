# 🚀 Freelancer App - Feature Inventory

This document provides a comprehensive list of all features currently implemented in the Freelancer App (v1.5.0), categorized by module.

## 📊 Dashboard (Command Center)
A high-performance, responsive central hub for business insights.
- **Responsive Design**: Automatically switches between a vertical list (Mobile) and a 2-column Masonry Grid (Desktop/Tablet) using `LayoutBuilder` and `StaggeredGrid`.
- **Staggered Animations**: Premium cascading entry animations for all dashboard cards.
- **Daily Focus**: Highlights the most urgent "In Progress" project based on deadline.
- **Smart Insights**: AI-like logic to summarize financial health and pending actions.
- **Time Burn Card**: Visualizes `Estimated vs. Actual` hours for active projects to prevent scope creep.
- **Financial Snapshot**: Real-time summary of Total Paid vs. Pending (Next 7 Days) revenue.
- **Daily Effort Chart**: 7-day bar chart visualization of time tracked.
- **Quick Actions**: Intelligent chips for urgent tasks (e.g., "Invoice Follow-up", "Proposal Response").
- **Global Search**: Quick access to finding anything in the app (`CommandSearch`).
- **Quick Notes**: Slide-up sheet for rapid thought capture.

## 📂 Project Management
- **CRUD Operations**: Create, Read, Update, Delete projects.
- **Progress Tracking**: Visual progress bars driven by completed tasks.
- **Health Indicators**: Automatic "Healthy", "At Risk", or "Behind" status based on budget realization vs. work progress.
- **Deadline Monitoring**: Visual warnings for overdue projects.
- **Magic Actions**: Contextual shortcuts (e.g., "Start Work" button on project cards).

## ⏱️ Task & Time Tracking
- **Integrated Timer**: Start/Stop capability for real-time tracking.
- **Daily Productivity**: "Total Tracked Today" summary with large, motivating counter.
- **Task Management**: Checkbox completion workflow with project association.
- **Smart Sorting**: Auto-sorts by Running > Active > Completed.
- **Manual Adjustments**: Edit time logs manually if the timer was forgotten.

## 💰 Invoicing & Finance
- **Invoice Generation**: Create invoices linked to projects or standalone ("External").
- **Smart Calculator**: Auto-calculates `Total = (Hours * Rate) + Tax`.
- **PDF Generation**: Professional PDF rendering with `printing` package.
- **Sharing & Printing**: Built-in OS share sheet and print support.
- **Status Workflow**: Mark as Paid with **Confetti Celebration** effect.
- **Multi-Currency Support**: Toggle between USD ($) and INR (₹).
- **GST/Tax Support**: Configurable tax percentages and breakdowns.

## 📝 Proposal System
- **Proposal Lifecycle**: Manage `Pending` -> `Accepted` -> `Rejected` states.
- **Template Engine**: Pre-filled templates for common services (Web Dev, Mobile App, SEO/Marketing).
- **PDF Styles**: Generate proposals in different aesthetic styles (Corporate, Creative, Minimal).
- **One-Click Conversion**: "Convert to Project" button instantly creates a project from an accepted proposal.

## 👥 Client Management (CRM)
- **Lifetime Value (LTV)**: Real-time calculation of total revenue per client.
- **Client Health Score**: Automatic categorization (VIP, Active, Dormant) based on recency and value.
- **Direct Actions**: One-tap buttons to Call or Email clients from the app.
- **Contextual History**: View all projects and invoices linked to a client.

## ⚙️ Settings & Customization
- **Theme Engine**: 
    - Full **Dark Mode** support.
    - Custom **Accent Color** picker (6 preset professional colors).
- **Preferences**: Set default Hourly Rate and Tax Rate.
- **Data Management**:
    - **Backup/Restore**: JSON-based clipboard export/import for easy data transfer.
    - **Factory Reset**: Clear all local data.
- **Security**: Visual indicator of AES-256 (conceptual) encryption status.
- **Account**: Firebase User profile integration.

## 🛠️ Technical Capabilities
- **Offline-First**: Built on **Hive** NoSQL database for instant, offline access.
- **Instant Load**: Optimistic UI rendering using synchronous read (`getAllSync`) to prevent loading flickers.
- **Haptic Feedback**: Integrated vibrations for interactions (Success, Error, Selection).
- **Routing**: `GoRouter` for deep linking and declarative navigation.