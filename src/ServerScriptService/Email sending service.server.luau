local HttpService = game:GetService("HttpService")

-- CONFIGURATION
local API_TOKEN = "mlsn.9dc405c15467a3463b744bc91832208a02487e1df830c85cee217a4e6238fa2a" -- Replace this with the token you just generated!
local FROM_EMAIL = "notifications@test-r83ql3p6o80gzw1j.mlsender.net" -- Must match what you verified in MailerSend
local TO_EMAIL = "anaclaireellen@gmail.com" -- kani ray ilisdi ace 

local function sendEmail(subject, textContent)
	local url = "https://api.mailersend.com/v1/email"

	local payload = {
		["from"] = { ["email"] = FROM_EMAIL },
		["to"] = { { ["email"] = TO_EMAIL } },
		["subject"] = subject,
		["text"] = textContent
	}

	local success, response = pcall(function()
		return HttpService:PostAsync(
			url,
			HttpService:JSONEncode(payload),
			Enum.HttpContentType.ApplicationJson,
			false,
			{ ["Authorization"] = "Bearer " .. API_TOKEN }
		)
	end)

	if success then
		print("Email sent successfully!")
	else
		warn("Failed to send email: " .. tostring(response))
	end
end

-- TEST: Call this function to trigger the email
sendEmail("Brighthaven", "Captain Kapa here! Ace has arrived at Brighthaven Rescue Shelter and is ready to begin their frist rescue mission. They'll be learning to share supplies fairly using division with remainders. I'll report back when they've mastered a level!")