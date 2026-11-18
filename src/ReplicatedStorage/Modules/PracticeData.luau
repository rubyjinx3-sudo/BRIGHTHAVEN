local PracticeData = {}

function PracticeData.generateSteps(dividend, divisor)
	local steps = {}
	local remaining = dividend

	-- Step 1: Big chunk (x10)
	if remaining >= divisor * 10 then
		local sub = divisor * 10
		remaining -= sub
		table.insert(steps, {
			title = "Step 1: Start Big",
			hint = string.format("Try taking away a big chunk first!\n\nPick the <b>×10</b> button, then calculate <b>%d × 10</b>.", divisor),
			explanation = "Great choice! Now subtract that amount from your total remaining."
		})
	end

	-- Step 2: Medium chunk (x5)
	if remaining >= divisor * 5 then
		local sub = divisor * 5
		remaining -= sub
		table.insert(steps, {
			title = string.format("Step %d: Keep Going", #steps + 1),
			hint = string.format("Let's take away another chunk!\n\nPick the <b>×5</b> button, then multiply <b>%d × 5</b>.", divisor),
			explanation = "Nice work! Notice how much smaller the remaining total is now."
		})
	end

	-- Step 3: Small chunks (x2)
	while remaining >= divisor * 2 do
		local sub = divisor * 2
		remaining -= sub
		table.insert(steps, {
			title = string.format("Step %d: Smaller Chunks", #steps + 1),
			hint = string.format("Select the <b>×2</b> button to chip away a smaller amount.", divisor),
			explanation = "Good job! Keep going until you can't fit any more chunks."
		})
	end

	-- Step 4: Final chunk (x1)
	if remaining >= divisor then
		local sub = divisor * 1
		remaining -= sub
		table.insert(steps, {
			title = string.format("Step %d: Final Stretch", #steps + 1),
			hint = string.format("You're almost done! Pick <b>×1</b> to subtract one last group of <b>%d</b>.", divisor),
			explanation = "Awesome! You've brought the remaining total down as far as it can go."
		})
	end

	return steps
end

return PracticeData
