import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "Learn how Kapsa collects, uses, and protects your personal data.",
};

export default function PrivacyPolicy() {
  return (
    <div className="pt-32 pb-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="mb-12">
          <h1 className="font-heading text-4xl font-bold text-white">Privacy Policy</h1>
          <p className="mt-3 text-white/40">Last updated: February 19, 2026</p>
        </div>

        <div className="prose-custom space-y-8">
          <Section title="1. Introduction">
            <p>
              Welcome to Kapsa (&ldquo;we,&rdquo; &ldquo;our,&rdquo; or &ldquo;us&rdquo;). This Privacy Policy explains how we collect,
              use, disclose, and safeguard your information when you use our mobile application Kapsa
              (the &ldquo;App&rdquo;), available on iOS. We are committed to protecting your privacy and ensuring
              the security of your personal data.
            </p>
            <p>
              By using Kapsa, you agree to the collection and use of information in accordance with
              this policy. If you do not agree, please do not use the App.
            </p>
          </Section>

          <Section title="2. Information We Collect">
            <h4>2.1 Information You Provide</h4>
            <ul>
              <li><strong>Account Information:</strong> When you create an account, we collect your name and email address through Apple Sign-In or email authentication.</li>
              <li><strong>Study Materials:</strong> Documents, photos, notes, PDFs, and audio recordings you upload to the App for processing.</li>
              <li><strong>User-Generated Content:</strong> Flashcards, quizzes, study plans, and other content you create within the App.</li>
              <li><strong>Profile Information:</strong> Your study preferences, selected courses, study time preferences, and academic goals.</li>
            </ul>

            <h4>2.2 Information Collected Automatically</h4>
            <ul>
              <li><strong>Usage Data:</strong> App interactions, feature usage, study streaks, session duration, and engagement metrics.</li>
              <li><strong>Device Information:</strong> Device type, operating system version, unique device identifiers, and app version.</li>
              <li><strong>Performance Data:</strong> Crash reports, error logs, and performance metrics to improve App stability.</li>
            </ul>
          </Section>

          <Section title="3. How We Use Your Information">
            <ul>
              <li>Provide, maintain, and improve the App and its features</li>
              <li>Process your study materials using AI to generate flashcards, quizzes, and summaries</li>
              <li>Personalize your study experience and recommendations</li>
              <li>Track your study progress, streaks, and performance analytics</li>
              <li>Process subscription payments through Apple&apos;s in-app purchase system</li>
              <li>Send relevant notifications about your study schedule and achievements</li>
              <li>Diagnose technical issues and improve App performance</li>
              <li>Comply with legal obligations</li>
            </ul>
          </Section>

          <Section title="4. AI Data Processing">
            <p>
              Kapsa uses artificial intelligence to process your study materials. When you upload
              documents, photos, or audio recordings:
            </p>
            <ul>
              <li>Your content is sent to our AI processing services (hosted by Replicate, Inc.) for text extraction, summarization, flashcard generation, and quiz creation.</li>
              <li>AI-processed content is stored in our secure database (hosted by Supabase) and associated with your account.</li>
              <li>We do not use your study materials to train AI models. Your content is processed solely to provide you with study tools.</li>
              <li>AI-generated content (flashcards, quizzes, summaries) is stored in your account and can be deleted at any time.</li>
            </ul>
          </Section>

          <Section title="5. Data Storage and Security">
            <p>
              Your data is stored securely using Supabase, a cloud database platform with
              enterprise-grade security. We implement appropriate technical and organizational
              measures to protect your personal information, including:
            </p>
            <ul>
              <li>Encryption of data in transit (TLS/SSL) and at rest</li>
              <li>Row-level security policies ensuring users can only access their own data</li>
              <li>Regular security audits and monitoring</li>
              <li>Secure authentication through Supabase Auth with support for Apple Sign-In</li>
            </ul>
          </Section>

          <Section title="6. Subscription and Payment Data">
            <p>
              Kapsa offers premium features through in-app subscriptions managed by Apple&apos;s App
              Store and RevenueCat:
            </p>
            <ul>
              <li>Payment processing is handled entirely by Apple. We do not collect, store, or have access to your credit card or payment information.</li>
              <li>RevenueCat manages subscription status and entitlements. They receive an anonymous app user ID to track your subscription status.</li>
              <li>We store your subscription status (free or pro) to provide appropriate feature access.</li>
            </ul>
          </Section>

          <Section title="7. Third-Party Services">
            <p>We use the following third-party services:</p>
            <ul>
              <li><strong>Supabase:</strong> Database, authentication, and file storage</li>
              <li><strong>Replicate:</strong> AI model hosting for text extraction, summarization, and content generation</li>
              <li><strong>RevenueCat:</strong> Subscription management and in-app purchase processing</li>
              <li><strong>Apple:</strong> Authentication (Sign in with Apple) and payment processing</li>
            </ul>
            <p>
              Each third-party service has its own privacy policy governing their use of your data.
              We encourage you to review their policies.
            </p>
          </Section>

          <Section title="8. Data Retention">
            <p>
              We retain your personal data for as long as your account is active or as needed to
              provide services. You can request deletion of your account and associated data at any
              time by contacting us. Upon account deletion:
            </p>
            <ul>
              <li>Your profile information and study materials will be permanently deleted</li>
              <li>AI-generated content associated with your account will be removed</li>
              <li>Anonymized usage analytics may be retained for product improvement</li>
            </ul>
          </Section>

          <Section title="9. Your Rights">
            <p>Depending on your jurisdiction, you may have the right to:</p>
            <ul>
              <li>Access your personal data</li>
              <li>Correct inaccurate data</li>
              <li>Delete your account and data</li>
              <li>Export your data in a portable format</li>
              <li>Opt out of non-essential data collection</li>
              <li>Withdraw consent for AI processing of your materials</li>
            </ul>
            <p>
              To exercise any of these rights, please contact us at the email address below.
            </p>
          </Section>

          <Section title="10. Children's Privacy">
            <p>
              Kapsa is not intended for children under the age of 13. We do not knowingly collect
              personal information from children under 13. If we learn that we have collected data
              from a child under 13, we will delete it promptly. If you believe a child under 13 has
              provided us with personal data, please contact us.
            </p>
          </Section>

          <Section title="11. Changes to This Policy">
            <p>
              We may update this Privacy Policy from time to time. We will notify you of any changes
              by posting the new policy on this page and updating the &ldquo;Last updated&rdquo; date. We
              encourage you to review this policy periodically.
            </p>
          </Section>

          <Section title="12. Contact Us">
            <p>
              If you have any questions about this Privacy Policy or our data practices, please
              contact us at:
            </p>
            <ul>
              <li><strong>Email:</strong> support@kapsa.app</li>
              <li><strong>Developer:</strong> Bagasy Studio</li>
            </ul>
          </Section>
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h3 className="font-heading text-xl font-semibold text-white mb-4">{title}</h3>
      <div className="space-y-3 text-white/50 text-[15px] leading-relaxed [&_h4]:text-white/70 [&_h4]:font-semibold [&_h4]:mt-4 [&_h4]:mb-2 [&_h4]:text-base [&_ul]:list-disc [&_ul]:pl-5 [&_ul]:space-y-2 [&_strong]:text-white/60">
        {children}
      </div>
    </section>
  );
}
