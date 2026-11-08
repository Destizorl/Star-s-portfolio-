# Star Jennie Portfolio — Vercel + Supabase

A responsive portfolio with a private content manager. The lady's original portrait and laptop artwork remain embedded directly in `index.html` as fallback artwork. An authorised administrator can replace the portrait, tune its fit and position, edit text/services/portfolio items, customise the brand colours, preview desktop/mobile layouts, and publish changes.

## Stack
- Static HTML/CSS/JavaScript hosted on Vercel
- One Vercel serverless function (`/api/config`) exposes only the Supabase public project URL and publishable/anon key from server environment variables
- Supabase Auth for administrator sign-in
- Supabase Postgres for published website content
- Supabase Storage (`site-media`) for hero and portfolio images
- Row Level Security (RLS) allowlist; no service-role key in browser code

## 1. Create and configure Supabase
1. Create a project at https://supabase.com/dashboard.
2. Open **SQL Editor** and run the complete `supabase/setup.sql` file.
3. Open **Project Settings → API** (or **API Keys**) and copy the Project URL and the publishable key (or legacy anon key). Never use a `service_role` or secret key in the website.
4. Open **Authentication → Users** and create the administrator user with the email Star Jennie will use. Set a strong password. Keep public sign-ups disabled. If email confirmation is enabled, confirm the user before first login.
5. Copy the new Auth user's UUID. In SQL Editor, run:

   ```sql
   insert into public.admin_users (user_id)
   values ('PASTE-THE-AUTH-USER-UUID-HERE');
   ```

   This explicit allowlist grants editing rights. A normal authenticated user cannot add themselves.

## 2. Deploy to Vercel
1. Push this complete folder to a GitHub repository. Keep `.env.local` out of Git.
2. In https://vercel.com/dashboard choose **Add New → Project** and import the repository.
3. Select **Other** as the Framework Preset. Leave the Build Command and Output Directory empty (the HTML/CSS/JS files are served as static assets; `/api/config.js` is deployed as a Vercel Function). Leave the Root Directory at the project root.
4. In **Project → Settings → Environment Variables**, add these for Production (and Preview/Development if needed):
   - `SUPABASE_URL` = your Supabase Project URL
   - `SUPABASE_ANON_KEY` = your Supabase publishable key or legacy anon key
5. Click **Deploy**. If you add/change environment variables later, redeploy.
6. Your public website is the Vercel project URL (`https://your-project.vercel.app/`). The private manager is `https://your-project.vercel.app/admin.html`.

## 3. Test locally (optional)
1. Install Node.js 20 or newer and the Vercel CLI (`npm install -g vercel`).
2. Copy `.env.example` to `.env.local` and fill in the same Supabase URL and publishable/anon key.
3. From the project folder run `vercel dev` and open the local URL it prints. This starts the `/api/config` function as well as the static pages.

## Admin workflow
- Sign in at `/admin.html` with the allowlisted Supabase Auth account.
- Edit the heading, intro, about text, services and portfolio entries.
- Upload a replacement hero portrait or select the original embedded portrait. Uploaded images are stored in Supabase Storage; a replacement becomes the active public hero only after publishing.
- Adjust portrait alignment, scale and fit. `contain` is the safe default to avoid distortion/cropping.
- Change the primary, secondary, accent, body text, page background and footer colours. The editor checks key text/button/footer contrast before preview or publishing.
- **Preview changes** opens a private same-browser preview with Desktop and Mobile widths. It does not update the published database row.
- **Save & publish** updates the single published content row. Visitors see the new content on refresh.

## Security
- Only the Supabase publishable/anon key is used by the browser. Never put the service-role/secret key in Vercel environment variables used by this site, in `VITE_` variables, or in Git.
- Public read access is limited to published content and images in the public `site-media` bucket. Only Auth users whose UUID is listed in `admin_users` can update content or upload/change/delete media.
- Keep public sign-ups disabled. Create and allowlist administrator accounts manually.
- Use a strong unique password and enable MFA for the admin account where available.
- The admin page is marked noindex; this is not the security boundary. Supabase Auth and RLS enforce access.
- Portfolio/hero images are public because the portfolio is public. Do not upload private or sensitive photographs.

## Operational notes
- This package is prepared for your Supabase project, but is not connected to a real project until you run the SQL setup and configure the two Vercel environment variables.
- No Vercel deployment or custom domain has been created from this chat.
- Old uploaded images are not automatically deleted when a photo is replaced. This avoids breaking a published image or a cached page. Remove obsolete files from Supabase Storage only after confirming they are no longer referenced.
- For a custom domain, add it in Vercel Project → Settings → Domains. Set the Supabase Auth Site URL to the deployed domain. Add any local/preview callback URLs only if you later use email-link authentication.
