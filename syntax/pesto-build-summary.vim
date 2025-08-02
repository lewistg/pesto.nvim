syn match pestoSectionHeader "^\s*\[\(+\|-\)]\s.*$" contains=pestoSectionHeaderLeadingWhitespace,pestoSectionToggleButton,pestoSectionTargetSectionHeader,pestoTargetLogsSectionHeader
syn match pestoSectionHeaderLeadingWhitespace "^\s*" contained nextgroup=pestoSectionToggleButton 
syn match pestoSectionToggleButton "\[\(+\|-\)]"hs=s+1,he=e-1 contained nextgroup=pestoSectionTargetSectionHeader,pestoTargetLogsSectionBazelLabel skipwhite

syn match pestoSectionTargetSectionHeader "\(Failed\|Successful\) targets (\d\+)" contained contains=pestoSectionTargetSectionHeaderTitle,pestoSectionTargetSectionHeaderTitle
syn match pestoSectionTargetSectionHeaderTitle "\(Failed\|Successful\) targets" contained nextgroup=pestoSectionTargetSectionHeaderTargetCount skipwhite
syn match pestoSectionTargetSectionHeaderTargetCount "(\d\+)"hs=s+1,he=e-1 contained 

syn match pestoTargetLogsSectionBazelLabel "//.*$" contained

hi def link pestoSectionToggleButton Constant

hi def link pestoSectionTargetSectionHeaderTitle Include
hi def link pestoSectionTargetSectionHeaderTargetCount Constant

hi def link pestoTargetLogsSectionBazelLabel Tag
