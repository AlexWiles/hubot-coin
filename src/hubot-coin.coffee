# Description:
#   Mine a currency and send it to other people.
#   A user mines coins by saying the mining word.
#   The probability of the mining word rewarding a user with a coin is set by the mining rate.
#   You cannot spend coins you do not have.
#
# Configuration:
#   HUBOT_COIN_NAME - the name of your currency
#   HUBOT_MINING_WORD - comma separated trigger words for mining
#   HUBOT_MINING_RATE - the probability a user is rewarded with a coin after saying the mining word
#
# Commands:
#   @<name> + <amount>  -- send coins to a user
#   <mining word(s)>    -- mine coins
#   wallet              -- see your coin balance
#
# Author:
#   alexwiles

coinName = process.env.HUBOT_COIN_NAME || "hubotcoin"
miningWords = process.env.HUBOT_MINING_WORD || "hubot"
miningRate = process.env.HUBOT_MINING_RATE || 0.5

module.exports = (robot) ->
  robot.brain.on "loaded", ()-> robot.brain.data.hubotCoin ||= {}

  miningWordRegex = new RegExp(miningWords.split(',').join('|'),"i")
  robot.hear miningWordRegex, (msg) ->
    if Math.random() < miningRate
      user = msg.message.user.name.toLowerCase()
      addCoin(user, 1)
      msg.send user + " mined 1 #{coinName}"

  robot.hear /wallet/i, (msg) ->
    user = msg.message.user.name.toLowerCase()
    total = robot.brain.data.hubotCoin[user] ||= 0
    msg.send "#{user} has #{total} #{coinName}"

  robot.hear /(@[a-z]+)(\s*\+\s*)([0-9]+\.?([0-9]*)?)/i, (msg) ->
    sender = msg.message.user.name.toLowerCase()
    [dummy, recipient, operator, amountString] = msg.match
    amount = Number(amountString) || 1
    if sendCoin(sender, recipient, amount)
      msg.send "#{sender} sent #{amount} #{coinName} to #{recipient}"
    else
      msg.send "#{sender}, you dont have enough #{coinName} to do that"

  addCoin = (user, amount) ->
    robot.brain.data.hubotCoin[user] ||= 0
    robot.brain.data.hubotCoin[user] += amount
    robot.brain.save()

  sendCoin = (sender, recipient, amount) ->
    senderWorth = robot.brain.data.hubotCoin[sender] ||= 0
    if senderWorth >= amount
      addCoin(recipient, amount)
      addCoin(sender, -amount)
      return true
    return false
