local StringUtils = {}

function StringUtils.formatMoney(amount: number): string
	if amount >= 1000000 then
		return string.format("%.1fM$", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK$", amount / 1000)
	else
		return amount .. "$"
	end
end

function StringUtils.formatButtonText(itemName: string, cost: number): string
	return itemName .. " - " .. StringUtils.formatMoney(cost)
end

return StringUtils
