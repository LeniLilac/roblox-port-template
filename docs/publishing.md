# Publishing and growth

What it takes to make a game public, reach younger players, be recommended
and advertise. Checked against Roblox's docs on 2026-11-17. These rules have
changed several times in 2025 and 2026, so recheck the linked pages before
relying on a number.

## Accounts and a group

A setup that keeps risk apart:

- **Owner account:** owns the group (community) and does nothing else.
  Since 2026 the publishing requirements below are checked on the **group
  owner** for the group's games, so this account carries the age check, ID
  verification and any Roblox Plus subscription. Turn on 2-step
  verification and keep its recovery details safe: if it's banned, the
  group and its games are stuck.
- **Uploader account:** owns the Open Cloud key `tools/assets.cmd` uses,
  with a role that may only manage the group's assets. If moderation
  strikes an upload, it hits this account, not the owner or your own.
- **Your own account:** edits and publishes places (a role with **Edit
  experiences** and **Publish experiences**; members who publish need
  2-step verification).
- **Testers:** a role with **Playtest experiences**. To let them into the
  live private game (not just Studio), set the audience to **Limited ›
  Playtesters**. **Limited › Community Members** opens it to every member.
- Before the first upload, turn on **Asset Privacy** for the group
  ([asset-sources.md](asset-sources.md)).

## Making a game public (players 16+)

[Publish experiences](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places):

- the account has completed an age check;
- it's in good standing and at least 2 days old;
- the content maturity and compliance questionnaire is complete for the game.

At most **5** never-public experiences can be made public per day. The
audience is set in the Creator Dashboard under Configure › Settings ›
Audience.

## Reaching all ages (Roblox Kids and Select)

[Roblox Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select):

- **Account:** ID verification (or parent-linked age verification) and
  2-step verification.
- **Payment, either:** a refundable **1,000 Robux** fee per game, or
  Roblox Plus or Premium for **2 consecutive months**. The fee is refunded
  90 days after the game becomes eligible, or 90 days after payment if it
  never does. There's no refund if the game is removed for serious
  Community Standards violations.
- **Content:** Roblox Kids takes Minimal or Mild content; Select also takes
  Moderate (9+). The full Content Ratings Questionnaire is required.
- **Evaluation:** 250 unique plays by highly engaged, age-checked players
  within 60 days. A highly engaged player has enough account age and
  playtime in your game, and made any Roblox purchase in the last 60 days
  (not necessarily in your game). Roblox checks hourly that the plays come
  from real people, then runs a safety review. Progress shows in Creator
  Hub's **Audience Reach** dashboard.
- **Expedited review:** a refundable 50,000 Robux per game, without the
  engagement requirement.

Until it passes, the game is open to age-checked players 16+ only.

## Discovery

[Discovery](https://create.roblox.com/docs/discovery) and its
[FAQ](https://create.roblox.com/docs/discovery-faq):

- A **custom thumbnail** is required for Home recommendations.
- **Non-unique games** (title, thumbnails, description and place file close
  to an existing game) aren't prioritised for recommendations and rank
  lower in search. When several games look alike, Roblox favours the one
  that first had the unique metadata or place file. A thin reskin competes
  with its own original and loses. A banner on the Creator Dashboard says
  when reach has been reduced.
- **Mismatched metadata** (a thumbnail promising something the game doesn't
  have) is also held back.
- Signals that count: low first-play bounce, play days and playtime per
  user (capped at 60 minutes a day), and especially days played with
  friends, plus spend days.
- Live events (Experience events) get their own placement.

## Ads

[Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager):

- Sponsored thumbnails on Home and in search. You set a daily or lifetime
  budget, and Roblox auto-bids. Reports show cost per play, and return on ad
  spend for earnings campaigns.
- Pay by card (18+, USD) or with Robux converted to ad credits. One ad
  credit is $1, which is 263 Robux at the DevEx rate. Converting can't be
  undone, but unused credits come back when a campaign ends. Group games
  can use the group's ad credit.
- Typical cost per click is $0.10–0.50, about $0.25 on average, but that's
  third-party data, not Roblox's. Start small (around $10–20 a day) and
  compare thumbnails.
- The game must be public.

## Common Roblox policies for ports

- No "free Robux" themes, and no Roblox trademarks presented as your
  own ([porting-guide.md](porting-guide.md#monetization-within-robloxs-rules)).
- Paid random items need visible odds and a `PolicyService` check.
- Uploads must be yours or licensed ([asset-sources.md](asset-sources.md)).
  Audio is copyright-checked on upload.
- A port of a game you don't own the rights to is infringement. Keep the
  licence or permission on record.
