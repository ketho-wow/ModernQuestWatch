local ClickFrames = {}

local function OnMouseUp(self)
	if IsShiftKeyDown() then -- untrack quest
		local questID = GetQuestIDFromLogIndex(self.questIndex)
		for index, value in ipairs(QUEST_WATCH_LIST) do
			if value.id == questID then
				tremove(QUEST_WATCH_LIST, index)
			end
		end
		RemoveQuestWatch(self.questIndex)
		QuestWatch_Update()
	else -- open to quest log
		ShowUIPanel(QuestLogFrame)
		QuestLog_SetSelection(self.questIndex)
	end
	QuestLog_Update()
end

local function SetHighlightColor(self)
	self.headerText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b) -- 1, .82, 0
	for _, text in ipairs(self.objectiveTexts) do
		text:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b) -- 1, 1, 1
	end
end

local function SetNormalColor(self)
	self.headerText:SetTextColor(.75, .61, 0)
	for _, text in ipairs(self.objectiveTexts) do
		text:SetTextColor(.8, .8, .8)
	end
end

local function OnEnter(self)
	if self.completed then
		SetNormalColor(self) -- use normal colors instead as highlight
	else
		SetHighlightColor(self)
	end
end

local function OnLeave(self)
	if self.completed then
		SetHighlightColor(self)
	else
		SetNormalColor(self)
	end
end

local function CreateClickFrame(watchIndex, questIndex, headerText, objectiveTexts, completed)
	if not ClickFrames[watchIndex] then
		ClickFrames[watchIndex] = CreateFrame("Frame")
		ClickFrames[watchIndex]:SetScript("OnMouseUp", OnMouseUp)
		ClickFrames[watchIndex]:SetScript("OnEnter", OnEnter)
		ClickFrames[watchIndex]:SetScript("OnLeave", OnLeave)
	end
	local f = ClickFrames[watchIndex]
	f:SetAllPoints(headerText)
	f.watchIndex = watchIndex
	f.questIndex = questIndex
	f.headerText = headerText
	f.objectiveTexts = objectiveTexts
	f.completed = completed
end

hooksecurefunc("QuestWatch_Update", function()
	local watchTextIndex = 1
	for i = 1, GetNumQuestWatches() do
		local questIndex = GetQuestIndexForWatch(i)
		if questIndex then
			local numObjectives = GetNumQuestLeaderBoards(questIndex)
			if numObjectives > 0 then
				local headerText = _G["QuestWatchLine"..watchTextIndex]
				watchTextIndex = watchTextIndex + 1
				local objectivesGroup = {}
				local objectivesCompleted = 0

				for j = 1, numObjectives do
					local finished = select(3, GetQuestLogLeaderBoard(j, questIndex))
					if finished then
						objectivesCompleted = objectivesCompleted + 1
					end
					tinsert(objectivesGroup, _G["QuestWatchLine"..watchTextIndex])
					watchTextIndex = watchTextIndex + 1
				end
				CreateClickFrame(i, questIndex, headerText, objectivesGroup, objectivesCompleted == numObjectives)
			end
		end
	end
	-- hide/show frames so it doesnt eat clicks, since we cant parent to a FontString
	for _, frame in pairs(ClickFrames) do
		frame[GetQuestIndexForWatch(frame.watchIndex) and "Show" or "Hide"](frame)
	end
end)

local function OnEvent(self, event, questIndex)
	AutoQuestWatch_Insert(questIndex, QUEST_WATCH_NO_EXPIRE)
end

local f = CreateFrame("Frame")
f:RegisterEvent("QUEST_ACCEPTED")
f:SetScript("OnEvent", OnEvent)
