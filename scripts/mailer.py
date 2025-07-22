#!/usr/bin/env python3
"""
Email notification script for Codemagic CI/CD
Uses SMTP to send build notifications
"""

import os
import smtplib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

def send_email(to_email, subject, body):
    """Send email using SMTP"""
    
    # Get SMTP configuration from environment variables
    smtp_server = os.getenv('EMAIL_SMTP_SERVER', 'smtp.gmail.com')
    smtp_port = int(os.getenv('EMAIL_SMTP_PORT', '587'))
    smtp_user = os.getenv('EMAIL_SMTP_USER', '')
    smtp_pass = os.getenv('EMAIL_SMTP_PASS', '')
    
    if not all([smtp_user, smtp_pass]):
        print("❌ SMTP credentials not configured")
        return False
    
    try:
        # Create message
        msg = MIMEMultipart()
        msg['From'] = smtp_user
        msg['To'] = to_email
        msg['Subject'] = subject
        
        # Add body
        msg.attach(MIMEText(body, 'plain'))
        
        # Create SMTP session
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_user, smtp_pass)
        
        # Send email
        text = msg.as_string()
        server.sendmail(smtp_user, to_email, text)
        server.quit()
        
        print(f"✅ Email sent successfully to {to_email}")
        return True
        
    except Exception as e:
        print(f"❌ Failed to send email: {str(e)}")
        return False

def main():
    """Main function"""
    if len(sys.argv) < 4:
        print("Usage: python3 mailer.py <to_email> <subject> <body>")
        sys.exit(1)
    
    to_email = sys.argv[1]
    subject = sys.argv[2]
    body = sys.argv[3]
    
    print(f"📧 Sending email to: {to_email}")
    print(f"📝 Subject: {subject}")
    
    success = send_email(to_email, subject, body)
    
    if success:
        print("✅ Email notification completed")
        sys.exit(0)
    else:
        print("❌ Email notification failed")
        sys.exit(1)

if __name__ == "__main__":
    main() 