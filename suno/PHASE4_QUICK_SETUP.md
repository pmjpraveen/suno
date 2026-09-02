# Phase 4 Quick Setup Guide

## 🚀 Getting Started with AI Analysis

### Step 1: Get an OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key (starts with `sk-...`)

### Step 2: Configure the Key

**Option A: Environment Variable (Recommended)**

```bash
# Add to your shell profile (~/.zshrc or ~/.bash_profile)
export OPENAI_API_KEY="sk-your-key-here"

# Then reload:
source ~/.zshrc
```

**Option B: Config File**

```bash
# Create config directory
mkdir -p ~/Library/Application\ Support/suno

# Create config file
cat > ~/Library/Application\ Support/suno/ai-config.json << EOF
{
  "openAIAPIKey": "sk-your-key-here"
}
EOF
```

### Step 3: Build and Run

```bash
# Build the app in Xcode
# The app will automatically detect the API key
# Check console for: "🧠 AI Analysis available: true"
```

### Step 4: Test It Out

1. **Record a sample meeting**
   - Click "Start Recording"
   - Talk for 30-60 seconds about a mock meeting
   - Mention some action items and decisions
   - Click "Stop"

2. **Wait for transcription**
   - Transcription happens automatically
   - Watch for "✅ Transcription complete!"

3. **AI analysis starts automatically**
   - Look for "🧠 Auto-starting AI analysis..."
   - Or click "Generate AI Summary" manually

4. **View results**
   - See Overview, Key Points, Decisions, Action Items, MOM
   - Click checkboxes to mark action items complete
   - Click timestamps to jump to that moment in recording

### Step 5: Verify Everything Works

**Console Logs to Look For:**

```
🎬 RecordingViewModel INIT started
✅ MeetingDetector created
🧠 AI Analysis available: true
🎙️ Starting transcription for: ...
✅ Transcription complete!
🧠 Auto-starting AI analysis...
🌐 Using OpenAI API for analysis
✅ AI analysis completed!
```

**If You See Issues:**

```
🧠 AI Analysis available: false
```
→ Check your API key configuration

```
❌ AI analysis failed: serviceUnavailable
```
→ Make sure API key is set correctly

```
❌ OpenAI API error (401): Incorrect API key
```
→ Verify your key is valid

```
❌ OpenAI API error (429): Rate limit exceeded
```
→ You've exceeded your API quota; wait or upgrade plan

## 🧪 Sample Meeting Script for Testing

Use this for realistic test data:

```
"Hi everyone, this is our Q4 planning meeting on September 2nd. 
Present are Sarah, Mike, and Jordan.

Our main objective today is to prioritize features for the next sprint.

First topic: We discussed the performance optimization work. 
Sarah mentioned that page load times are currently around 3 seconds, 
which is too slow. We decided to make this the top priority.

Mike will create a technical specification for the performance 
improvements by end of next week.

Second topic: User onboarding feedback. Jordan shared that 15% 
of new users drop off during signup. We decided to redesign the 
onboarding flow.

Sarah volunteered to schedule user research sessions by Friday 
to better understand the pain points.

Third decision: We approved an additional $5,000 budget for 
infrastructure improvements.

Action items:
- Mike: Write performance spec (Due: September 9th)
- Sarah: Schedule user research (Due: September 5th)
- Jordan: Review current onboarding metrics (Due: tomorrow)

Any questions? No? Great, meeting adjourned."
```

This should generate:
- **Overview**: Meeting about Q4 planning and sprint priorities
- **Key Points**: Performance issues, onboarding problems, budget approval
- **Decisions**: 3 decisions with context
- **Action Items**: 3 items with assignees and due dates
- **MOM**: Formatted document with all sections

## 📊 Expected API Costs

**OpenAI GPT-4o Pricing (as of Sep 2024):**
- Input: $5 / 1M tokens
- Output: $15 / 1M tokens

**Typical Meeting Analysis:**
- 30-minute meeting ≈ 5,000 words ≈ 6,500 tokens input
- Analysis response ≈ 1,000 tokens output
- Cost per analysis: ~$0.05

**Monthly estimate for 20 meetings:** ~$1

Very affordable for the value provided!

## 🔒 Security Reminders

✅ **Do:**
- Use environment variables
- Store keys in config files (add to .gitignore)
- Consider a backend proxy for production

❌ **Don't:**
- Hardcode keys in source code
- Commit keys to git
- Share keys publicly
- Use personal keys in shared environments

## 🆘 Troubleshooting

### "AI Analysis not available"

1. Check environment variable:
   ```bash
   echo $OPENAI_API_KEY
   ```

2. Check config file:
   ```bash
   cat ~/Library/Application\ Support/suno/ai-config.json
   ```

3. Verify key starts with `sk-`

4. Restart Xcode and rebuild

### "Analysis failed"

1. Check internet connection
2. Verify API key is valid
3. Check OpenAI status: https://status.openai.com
4. Look at console error message
5. Try "Retry Analysis" button

### Analysis is slow

1. Normal: First analysis takes 30-60 seconds
2. Check internet speed
3. Longer transcripts take more time
4. Max wait time: 2 minutes (then timeout)

## 🎯 Next Steps

Once Phase 4 is working:

1. **Customize prompts** in `MeetingAnalysisPrompt.swift`
2. **Adjust temperature** in `LLMAnalysisService.swift` (0.3 = consistent, 0.7 = creative)
3. **Change model** to `gpt-4-turbo` or `gpt-3.5-turbo` for cost/quality tradeoff
4. **Add export features** (PDF, email, calendar integration)
5. **Implement Foundation Models** when SDK is available

## 📚 Additional Resources

- OpenAI API Docs: https://platform.openai.com/docs
- GPT-4 Guide: https://platform.openai.com/docs/guides/gpt
- Structured Outputs: https://platform.openai.com/docs/guides/structured-outputs
- Rate Limits: https://platform.openai.com/docs/guides/rate-limits

---

**Need Help?** Check the detailed docs in `PHASE4_AI_ANALYSIS_COMPLETE.md`
