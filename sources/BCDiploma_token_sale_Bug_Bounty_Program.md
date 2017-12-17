# BCDiploma token sale Bug Bounty Program

Thank you for visiting the BCDiploma Bug Bounty.

BCDiploma aims to become the global standard of degree certification. 
Please find our documentation:
* Whitepaper: https://www.bcdiploma.com/img/BCD-WhitePaper_last.pdf
* One Pager: https://www.bcdiploma.com/img/BCD_OnePager_last.pdf

You can also join our community:
* on Telegram: https://t.me/BCDiploma
* on https://www.bcdiploma.com


If you've already read this information and have found a bug you'd like to submit to BCD for review, please use this form: [Submit a Bug](https://goo.gl/forms/R0w3vaKdjv3s7SqY2).

## Rewards

Paid out **Rewards** in ether are guided by the **Severity** category of the submission according to [OWASP](https://github.com/weifund/weifund-contracts/blob/master/BUG-BOUNTY-DETAILS.md)’s risk model, up to a maximum of $5,000 for campaign.

## Rules

* Issues that have already been submitted by another user or are already known to BCD are not eligible for bounty rewards
* Public disclosure of a vulnerability without BCD's prior consent results in ineligibility for a bounty

## Targets

### In scope:

**BCDT Smart Contracts**: https://github.com/VinceBCD/BCDiploma/tree/master/sources/contracts/BCDToken

**Examples of what's in scope** 

* Being able to obtain more tokens than expected
* Being able to obtain tokens from someone without their permission
* Bugs that lead to loss or theft of ether
* Bugs causing a transaction to be sent that was different from what user confirmed: for example, user transfers 10 ether in the UI, but exactly 10 wasn't transferred.
* Bugs that could lead to the direct loss of funds such as paying out to non-intended payout beneficiaries
* Bugs that lead to tokens being claimed before they should be
* Bugs that lead to the wrong amount of funds being refunded when a campaign is not successful
* Different behavior than expected in specifications: https://github.com/VinceBCD/BCDiploma/blob/master/sources/contracts/BCDToken/README.md


### Out of scope:

* Known behaviors indicated in specifications: https://github.com/VinceBCD/BCDiploma/blob/master/sources/contracts/BCDToken/README.md
* Gas consumption improvement
* Code or comment style improvement

**Examples of what's out of scope**

* An address that has already contributed can be removed from the whitelist