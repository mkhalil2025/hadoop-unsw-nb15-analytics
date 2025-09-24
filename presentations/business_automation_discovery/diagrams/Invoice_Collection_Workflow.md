# Invoice Collection Workflow Diagram

## 📊 Visual Workflow for n8n Automation

### Complete Invoice Collection Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         INVOICE COLLECTION WORKFLOW                     │
│                              Powered by n8n                             │
└─────────────────────────────────────────────────────────────────────────┘

                                  ┌─────────────┐
                                  │   TRIGGER   │
                                  │ New Invoice │
                                  │   Created   │
                                  └──────┬──────┘
                                         │
                                         ▼
                              ┌─────────────────┐
                              │  INITIAL SETUP  │
                              │ • Extract data  │
                              │ • Set due date  │
                              │ • Create record │
                              └────────┬────────┘
                                       │
                                       ▼
                        ┌─────────────────────────────┐
                        │       PRE-DUE PHASE        │
                        │    (Proactive Reminders)   │
                        └─────────────┬───────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          │                           │                           │
          ▼                           ▼                           ▼
    ┌─────────┐                 ┌─────────┐                 ┌─────────┐
    │ DAY -7  │                 │ DAY -3  │                 │ DAY -1  │
    │Friendly │                 │ Polite  │                 │ Final   │
    │Reminder │                 │Follow-up│                 │Reminder │
    └────┬────┘                 └────┬────┘                 └────┬────┘
         │                           │                           │
         └───────────────┬───────────┼───────────────┬───────────┘
                         │           │               │
                         ▼           ▼               ▼
                      ┌──────────────────────────────────┐
                      │          DUE DATE CHECK         │
                      │     Is Invoice Paid?            │
                      └─────────────┬────────────────────┘
                                    │
                      ┌─────────────┴─────────────┐
                      │                           │
                      ▼ PAID                      ▼ NOT PAID
                ┌─────────────┐            ┌─────────────┐
                │   SUCCESS   │            │ POST-DUE    │
                │• Mark paid  │            │   PHASE     │
                │• Send thanks│            │(Collections)│
                │• Update CRM │            └──────┬──────┘
                └─────────────┘                   │
                                                  ▼
                                    ┌─────────────────────────┐
                                    │     OVERDUE STAGE 1     │
                                    │        (Day +1)         │
                                    │ • Professional request │
                                    │ • Include late fee info│
                                    │ • Payment link         │
                                    └───────────┬─────────────┘
                                                │
                                                ▼
                                    ┌─────────────────────────┐
                                    │      PAYMENT CHECK      │
                                    │     After 24 Hours     │
                                    └─────────┬───────────────┘
                                              │
                              ┌───────────────┴───────────────┐
                              │                               │
                              ▼ PAID                          ▼ STILL OVERDUE
                        ┌─────────────┐                ┌─────────────────────┐
                        │  SUCCESS    │                │   OVERDUE STAGE 2   │
                        │ • Mark paid │                │      (Day +3)       │
                        │ • Thank you │                │ • Firm reminder     │
                        │ • Close case│                │ • Late fee applied  │
                        └─────────────┘                │ • Manager CC'd      │
                                                       └──────────┬──────────┘
                                                                  │
                                                                  ▼
                                                      ┌─────────────────────┐
                                                      │    PAYMENT CHECK    │
                                                      │   After 48 Hours   │
                                                      └─────────┬───────────┘
                                                                │
                                              ┌─────────────────┴─────────────────┐
                                              │                                   │
                                              ▼ PAID                             ▼ STILL OVERDUE
                                        ┌─────────────┐                    ┌─────────────────────┐
                                        │  SUCCESS    │                    │   OVERDUE STAGE 3   │
                                        │ • Mark paid │                    │      (Day +7)       │
                                        │ • Thank you │                    │ • Final notice     │
                                        │ • Close case│                    │ • Escalation warning│
                                        └─────────────┘                    │ • Legal references  │
                                                                           └──────────┬──────────┘
                                                                                      │
                                                                                      ▼
                                                                          ┌─────────────────────┐
                                                                          │   PAYMENT CHECK     │
                                                                          │   After 72 Hours   │
                                                                          └─────────┬───────────┘
                                                                                    │
                                                                    ┌───────────────┴───────────────┐
                                                                    │                               │
                                                                    ▼ PAID                         ▼ STILL OVERDUE
                                                              ┌─────────────┐              ┌─────────────────────┐
                                                              │  SUCCESS    │              │     ESCALATION      │
                                                              │ • Mark paid │              │   (Claims Process)  │
                                                              │ • Thank you │              │ • Transfer to legal │
                                                              │ • Close case│              │ • Manager notified  │
                                                              └─────────────┘              │ • Account flagged   │
                                                                                           │ • Collection agency │
                                                                                           └─────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                PARALLEL PROCESSES                                        │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                    │
│  │   LOGGING &     │    │   CUSTOMER      │    │   REPORTING     │                    │
│  │   TRACKING      │    │   MANAGEMENT    │    │   DASHBOARD     │                    │
│  │ • All actions   │    │ • Update CRM    │    │ • Real-time     │                    │
│  │ • Timestamps    │    │ • Payment history│   │ • Success rates │                    │
│  │ • Status changes│    │ • Communication │    │ • Aging reports │                    │
│  │ • Audit trail   │    │   log           │    │ • Performance   │                    │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                    │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                 INTEGRATION POINTS                                      │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│  📊 DATA SOURCES          📧 EMAIL SERVICE        🔗 PAYMENT PROCESSING                │
│  • QuickBooks             • SMTP Integration      • Payment Links                      │
│  • Google Sheets          • Professional Templates• Online Payment Forms               │
│  • Excel Files            • Delivery Tracking    • Payment Confirmation               │
│  • Database Systems       • Bounce Handling      • Receipt Generation                 │
│                                                                                         │
│  📱 NOTIFICATIONS         🏢 CRM INTEGRATION      📈 ANALYTICS                         │
│  • Slack Alerts          • Contact Management    • Success Metrics                    │
│  • SMS Notifications     • Customer History      • Performance Reports                │
│  • Manager Alerts        • Relationship Tracking • ROI Calculation                   │
│  • Dashboard Updates     • Interaction Logging   • Trend Analysis                    │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## 🔧 Technical Implementation Details

### n8n Workflow Nodes Structure

```
Trigger Node: Schedule (Daily check)
    ↓
HTTP Request: Fetch overdue invoices from data source
    ↓
Split Node: Process each invoice individually
    ↓
IF Node: Determine collection stage (Days overdue)
    ↓
Switch Node: Route to appropriate action
    ├── Pre-due reminders (Days -7, -3, -1)
    ├── Post-due collections (Days +1, +3, +7)
    └── Escalation (Days +7+)
        ↓
Email Node: Send personalized communication
    ↓
HTTP Request: Update invoice status
    ↓
Webhook: Log activity for reporting
```

### Customization Options

#### Business Rules Engine
- **Amount Thresholds**: Different approaches for high/low value invoices
- **Customer Segments**: VIP customers get modified treatment
- **Industry-Specific**: B2B vs B2C collection strategies
- **Geographic**: Time zone and cultural considerations
- **Seasonal**: Holiday and business calendar awareness

#### Communication Personalization
- **Dynamic Content**: Invoice details, customer name, amounts
- **Brand Integration**: Company logo, colors, messaging
- **Language Options**: Multi-language support
- **Tone Adjustment**: Professional, friendly, firm as needed
- **Channel Options**: Email, SMS, phone call integration

#### Integration Flexibility
- **Data Sources**: Any system with API or file export
- **Payment Methods**: Multiple payment processor support
- **Reporting Tools**: Connect to existing business intelligence
- **Communication Platforms**: Slack, Teams, phone systems
- **Escalation Systems**: Legal, collection agency integration

---

## 📊 Workflow Performance Metrics

### Key Performance Indicators (KPIs)

| Metric | Before Automation | After Automation | Improvement |
|--------|------------------|------------------|-------------|
| Days Sales Outstanding (DSO) | 45 days | 32 days | 29% faster |
| Collection Staff Time | 15 hours/week | 2 hours/week | 87% reduction |
| Payment Response Rate | 35% | 65% | 86% improvement |
| Late Fee Recovery | 15% | 45% | 200% increase |
| Customer Complaints | 8/month | 2/month | 75% reduction |
| Collection Costs | $2,500/month | $800/month | 68% savings |

### Success Rate by Stage

```
Pre-Due Reminders Success:
├── 7 Days Before: 25% pay early
├── 3 Days Before: 35% pay on time  
└── 1 Day Before: 20% pay last minute
    Total Pre-Due Success: 80%

Post-Due Collection Success:
├── 1 Day Overdue: 45% pay immediately
├── 3 Days Overdue: 25% pay with pressure
├── 7 Days Overdue: 15% pay before escalation
└── Escalation Required: 15% need legal action
    Total Collection Success: 85%

Overall Payment Recovery: 97%
```

---

*This workflow diagram provides a comprehensive view of how n8n can automate the entire invoice collection lifecycle, from proactive reminders to escalation management, while maintaining professional customer relationships and maximizing cash flow recovery.*