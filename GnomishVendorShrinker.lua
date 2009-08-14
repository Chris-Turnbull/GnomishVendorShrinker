
local NUMROWS, ICONSIZE, GAP, SCROLLSTEP = 14, 17, 4, 5


for _,f in pairs{MerchantNextPageButton, MerchantPrevPageButton, MerchantPageText} do
	f:Hide()
	f.Show = f.Hide
end


local GVS = CreateFrame("frame", nil, MerchantFrame)
GVS:SetWidth(315)
GVS:SetHeight(294)
GVS:SetPoint("TOPLEFT", 21, -77)
GVS:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
GVS:Hide()


local function OnClick(self, button)
	if IsAltKeyDown() and not self.altcurrency then self:BuyItem(true)
	elseif IsModifiedClick() then HandleModifiedItemClick(GetMerchantItemLink(self:GetID()))
	elseif self.altcurrency then
		local id = self:GetID()
		local link = GetMerchantItemLink(id)
		self.link, self.texture = GetMerchantItemLink(id), self.icon:GetTexture()
		MerchantFrame_ConfirmExtendedItemCost(self)
	else self:BuyItem() end
end


local function BuyItem(self, fullstack)
	local id = self:GetID()
	local link = GetMerchantItemLink(id)
	if not link then return end

	local _, _, _, vendorStackSize, numAvailable = GetMerchantItemInfo(id)
	local maxPurchase = GetMerchantItemMaxStack(id)
	local _, _, _, _, _, _, _, itemStackSize = GetItemInfo(link)
	local quantity = fullstack and itemStackSize/vendorStackSize or 1
	if numAvailable > 0 and numAvailable < quantity then quantity = numAvailable end
	local purchased = 0
	while purchased < quantity do
		local buyamount = math.min(maxPurchase, quantity - purchased)
		purchased = purchased + buyamount
		BuyMerchantItem(id, buyamount)
	end
end


local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.tiptext then GameTooltip:SetText(self.tiptext) else GameTooltip:SetMerchantCostItem(self.index, self.itemIndex) end
end


local function OnLeave()
	GameTooltip:Hide()
	ResetCursor()
end


local function GSC(cash)
	if not cash then return end
	local g, s, c = floor(cash/10000), floor((cash/100)%100), cash%100
	if g > 0 and s == 0 and c == 0 then return string.format(" |cffffd700%d", g)
	elseif g > 0 and c == 0 then return string.format(" |cffffd700%d.|cffc7c7cf%02d", g, s)
	elseif g > 0 then return string.format(" |cffffd700%d.|cffc7c7cf%02d.|cffeda55f%02d", g, s, c)
	elseif s > 0 and c == 0 then return string.format(" |cffc7c7cf%d", s)
	elseif s > 0 then return string.format(" |cffc7c7cf%d.|cffeda55f%02d", s, c)
	else return string.format(" |cffc7c7cf%d", c) end
end


local function SetValue(self, text, icon, tiptext)
	self.text:SetText(text)
	self.icon:SetTexture(icon)
	self.tiptext, self.index, self.itemIndex = tiptext
	if tiptext == HONOR_POINTS then
		self.icon:SetPoint("RIGHT", -2, 0)
		self.text:SetPoint("RIGHT", self.icon, "LEFT", -GAP/2 + 2, 0)
	else
		self.icon:SetPoint("RIGHT")
		self.text:SetPoint("RIGHT", self.icon, "LEFT", -GAP/2, 0)
	end
	self:Show()
end


local function GetAltCurrencyFrame(frame)
	for i,v in ipairs(frame.altframes) do if not v:IsShown() then return v end end

	local anchor = #frame.altframes > 0 and frame.altframes[#frame.altframes].text
	local f = CreateFrame('Frame', nil, frame)
	f:SetWidth(ICONSIZE) f:SetHeight(ICONSIZE)
	f:SetPoint("RIGHT", anchor or frame.ItemPrice, "LEFT")

	f.icon = f:CreateTexture()
	f.icon:SetWidth(ICONSIZE) f.icon:SetHeight(ICONSIZE)

	f.text = f:CreateFontString(nil, nil, "NumberFontNormalSmall")

	f.SetValue = SetValue

	f:EnableMouse(true)
	f:SetScript("OnEnter", OnEnter)
	f:SetScript("OnLeave", OnLeave)

	table.insert(frame.altframes, f)
	return f
end


local function AddAltCurrency(frame, i)
	local lastframe = frame.ItemPrice
	local honorPoints, arenaPoints, itemCount = GetMerchantItemCostInfo(i)
	for j=itemCount,1,-1 do
		local f = frame:GetAltCurrencyFrame()
		local texture, price = GetMerchantItemCostItem(i, j)
		f:SetValue(price, texture)
		f.index, f.itemIndex = i, j
		lastframe = f.text
	end
	if arenaPoints > 0 then
		local f = frame:GetAltCurrencyFrame()
		f:SetValue(arenaPoints, "Interface\\PVPFrame\\PVP-ArenaPoints-Icon", ARENA_POINTS)
		lastframe = f.text
	end
	if honorPoints > 0 then
		local f = frame:GetAltCurrencyFrame()
		f:SetValue(honorPoints, "Interface\\PVPFrame\\PVP-Currency-".. UnitFactionGroup("player"), HONOR_POINTS)
		lastframe = f.text
	end
	frame.ItemName:SetPoint("RIGHT", lastframe, "LEFT", -GAP, 0)
end


local rows = {}
for i=1,NUMROWS do
	local row = CreateFrame('Button', nil, GVS) -- base frame
	row:SetHeight(21)
	row:SetPoint("TOP", i == 1 and GVS or rows[i-1], i == 1 and "TOP" or "BOTTOM")
	row:SetPoint("LEFT")
	row:SetPoint("RIGHT", -19, 0)

	row.BuyItem = BuyItem

	row:SetHighlightTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
	row:GetHighlightTexture():SetTexCoord(0, 1, 0, 0.578125)

	row:SetScript('OnClick', OnClick)
	row:SetScript('OnDragStart', function(self, button)
		MerchantFrame.extendedCost = nil
		PickupMerchantItem(self:GetID())
		if self.extendedCost then MerchantFrame.extendedCost = self end
	end)

	local icon = CreateFrame('Frame', nil, row)
	icon:SetHeight(ICONSIZE)
	icon:SetWidth(ICONSIZE)
	icon:SetPoint('LEFT', 2, 0)

	row.icon = icon:CreateTexture(nil, "BORDER")
	row.icon:SetAllPoints()

	local ItemName = row:CreateFontString(nil, nil, "GameFontNormalSmall")
	ItemName:SetPoint('LEFT', icon, "RIGHT", GAP, 0)
	ItemName:SetJustifyH('LEFT')
	row.ItemName = ItemName

	local ItemPrice = row:CreateFontString(nil, nil, "NumberFontNormalSmall")
	ItemPrice:SetPoint('RIGHT', row, -2, 0)
	row.ItemPrice = ItemPrice

	row.altframes = {}
	row.AddAltCurrency, row.GetAltCurrencyFrame = AddAltCurrency, GetAltCurrencyFrame

	row:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetMerchantItem(self:GetID())
		GameTooltip_ShowCompareItem()
		MerchantFrame.itemHover = self:GetID()
		if IsModifiedClick("DRESSUP") then ShowInspectCursor() else ResetCursor() end
	end)
	row:SetScript('OnLeave', function()
		GameTooltip:Hide()
		ResetCursor()
		MerchantFrame.itemHover = nil
	end)

	rows[i] = row
end


local offset = 0
local function Refresh()
	local n = GetMerchantNumItems()
	for i,row in pairs(rows) do
		local j = i + offset
		if j > n then
			row:Hide()
		else
			local name, itemTexture, itemPrice, itemStackCount, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(j)
			local link = GetMerchantItemLink(j)
			local color = link and select(4, GetItemQualityColor(select(3, GetItemInfo(link)))) or "|cffffffff"

			row.icon:SetTexture(itemTexture)
			row.ItemName:SetText((numAvailable > -1 and ("["..numAvailable.."] ") or "").. color.. (name or "<Loading item data>").. (itemStackCount > 1 and ("|r x"..itemStackCount) or ""))

			for i,v in pairs(row.altframes) do v:Hide() end
			row.altcurrency = extendedCost
			if extendedCost then
				row:AddAltCurrency(j)
				row.link, row.texture, row.extendedCost = link, itemTexture, true
			end
			if itemPrice > 0 then
				row.ItemPrice:SetText(GSC(itemPrice))
				row.Price = itemPrice
			end
			if extendedCost and (itemPrice <= 0) then
				row.ItemPrice:SetText()
				row.Price = 0
			elseif extendedCost and (itemPrice > 0) then
				row.ItemPrice:SetText(GSC(itemPrice))
			else
				row.ItemName:SetPoint("RIGHT", row.ItemPrice, "LEFT", -GAP, 0)
				row.extendedCost = nil
			end

			if isUsable then row.icon:SetVertexColor(1, 1, 1) else row.icon:SetVertexColor(.9, 0, 0) end
			row:SetID(j)
			row:Show()
		end
	end
end


local scrollbar = LibStub("tekKonfig-Scroll").new(GVS, 0, SCROLLSTEP)
local f = scrollbar:GetScript("OnValueChanged")
scrollbar:SetScript("OnValueChanged", function(self, value, ...)
	offset = math.floor(value)
	Refresh()
	return f(self, value, ...)
end)


local offset = 0
GVS:EnableMouseWheel(true)
GVS:SetScript("OnMouseWheel", function(self, value) scrollbar:SetValue(scrollbar:GetValue() - value * SCROLLSTEP) end)
GVS:SetScript("OnShow", function()
	scrollbar:SetMinMaxValues(0, math.max(0, GetMerchantNumItems() - NUMROWS))
	scrollbar:SetValue(0)
	Refresh()
end)


-- Reanchor the buyback button, it acts weird when switching tabs otherwise...
MerchantBuyBackItem:ClearAllPoints()
MerchantBuyBackItem:SetPoint("BOTTOMLEFT", 189, 90)


local function Show()
	for i=1,12 do _G["MerchantItem"..i]:Hide() end
	if GVS:IsShown() then Refresh() else GVS:Show() end
end
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", Show)


hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	GVS:Hide()
	for i=1,12 do _G["MerchantItem"..i]:Show() end
end)


if MerchantFrame:IsVisible() and MerchantFrame.selectedTab == 1 then Show() end


LibStub("tekKonfig-AboutPanel").new(nil, "GnomishVendorShrinker")
