# Railway Deployment Guide

## Prerequisites
- GitHub account
- Railway account (sign up at https://railway.app)
- Your code pushed to GitHub

## Deployment Steps

### 1. Push Your Code to GitHub
```bash
git add .
git commit -m "Prepare for Railway deployment"
git push origin main
```

### 2. Deploy on Railway

#### Option A: Using Railway Dashboard (Recommended)
1. Go to https://railway.app
2. Click **"Start a New Project"**
3. Select **"Deploy from GitHub repo"**
4. Choose your repository: `SmartCRM-backend`
5. Railway will automatically detect the Dockerfile

#### Option B: Using Railway CLI
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Deploy
railway up
```

### 3. Configure Environment Variables

In Railway Dashboard:
1. Go to your project
2. Click on **"Variables"** tab
3. Add the following variables:

```
NODE_ENV=production
PORT=<leave empty - Railway sets this automatically>
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key-here
FRONTEND_URL=https://your-frontend-url.com
```

**Important**: 
- Don't set `PORT` manually - Railway assigns it automatically
- Update `FRONTEND_URL` with your actual frontend URL
- Get Supabase credentials from your Supabase dashboard

### 4. Generate Domain

1. In Railway Dashboard, go to **"Settings"** tab
2. Click **"Generate Domain"** under "Networking"
3. Your API will be available at: `https://your-app.up.railway.app`

### 5. Verify Deployment

Check these endpoints:
- API Health: `https://your-app.up.railway.app/api`
- Swagger Docs: `https://your-app.up.railway.app/api/docs`

### 6. Update Frontend

Update your frontend's API URL to point to:
```
https://your-app.up.railway.app/api
```

## Monitoring

- **Logs**: View in Railway Dashboard → "Deployments" tab
- **Metrics**: Check CPU, Memory, Network usage in Dashboard
- **Alerts**: Set up in Railway settings

## Automatic Deployments

Railway automatically redeploys when you push to your main branch:
```bash
git add .
git commit -m "Update feature"
git push origin main
# Railway will automatically redeploy
```

## Troubleshooting

### Build Fails
- Check Railway logs for errors
- Ensure all dependencies are in `package.json`
- Verify Dockerfile syntax

### App Crashes
- Check environment variables are set correctly
- Verify Supabase credentials
- Check logs for error messages

### CORS Issues
- Update `FRONTEND_URL` environment variable
- Ensure frontend URL is correct (no trailing slash)

## Cost

- **Free Tier**: $5 credit/month, 500 hours
- **Pro Plan**: $20/month for unlimited usage
- Your app should fit comfortably in the free tier for development

## Support

- Railway Docs: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
