#!/usr/bin/perl -w


use strict;
use warnings;

package XMLlists;

use File::Compare;
use File::Copy;

use Exporter;
our @ISA= qw( Exporter );
our @EXPORT = qw(
	getAutoDir
	getFileWithPath
	getEnumFiles
	getNumFunction
	getInfo
	getXMLKeywords
	isAlwaysHardcodedEnum
	getNoType
	updateAutoFile
	isTwoLevelFile
	isDllExport
);

# first is a list of files with hardcoded Type settings in the DLL.
# this means changing any of those files in a way that will alter the list of Types will require a recompile.
sub isAlwaysHardcodedEnum
{
	my $file = shift;
	
	return 1 if $file eq "BasicInfos/CIV4DomainInfos.xml";
	return 1 if $file eq "BasicInfos/CIV4UnitAIInfos.xml";
	return 1 if $file eq "BasicInfos/CIV4InvisibleInfos.xml";
	return 1 if $file eq "GameInfo/CIV4GameOptionInfos.xml";
	return 1 if $file eq "GameInfo/CIV4PlayerOptionInfos.xml";
	return 1 if $file eq "GameInfo/CIV4WorldInfo.xml";
	return 1 if $file eq "Terrain/CIV4TerrainInfos.xml";
	return 1 if $file eq "Terrain/CIV4YieldCategoryInfos.xml";
	return 1 if $file eq "Terrain/CIV4YieldInfos.xml";
	return 1 if $file eq "Units/CIV4AutomateInfos.xml";
	return 1 if $file eq "Units/CIV4CommandInfos.xml";
	return 1 if $file eq "Units/CIV4ControlInfos.xml";
	return 1 if $file eq "Units/CIV4MissionInfos.xml";
	
	return 0;
}

sub getXMLlocation()
{
	return "../Assets/XML/";
}

sub getAutoDir
{
	return "DLLSources/autogenerated/";
}

sub getFileWithPath
{
	my $file = shift;
	
	foreach my $prefix (getXMLlocation(), getXMLlocation())
	{
		my $path = $prefix . $file;
		return $path if -e $path;
	}
	return undef;
}

sub getXMLKeywords
{
	my $file = shift;
	
	# first the non-standard enums. A few doesn't apply to the standard naming rules.
	return ("WorldSize", "WorldSizeTypes", "WORLDSIZE") if $file eq "GameInfo/CIV4WorldInfo.xml";
	
	my $basename = $file;
	my $enum = ""; # needs a buffer variable. The contents will not be used.
	($enum, $basename) = split("/", $file) if index($file, "/") != -1;
	$basename = substr($basename, 4) if lc(substr($basename, 0, 4)) eq "civ4";
	($basename) = split("Info", $basename);
	
	$enum = $basename . "Types";
	my $TYPE = uc($basename);
	
	# rename types. Not all apply to the standard
	$TYPE = "CIVIC_OPTION" if $file eq "CivEffects/CIV4CivicOptionInfos.xml";
	$TYPE = "LEADER" if $file eq "Civilizations/CIV4LeaderHeadInfos.xml";
	$TYPE = "FATHER_POINT" if $file eq "GameInfo/CIV4FatherPointInfos.xml";
	$TYPE = "YIELD_CATEGORY" if $file eq "Terrain/CIV4YieldCategoryInfos.xml";
	
	if ($file eq "BasicInfos/CIV4BasicInfos.xml")
	{
		$basename = "Concept";
		$enum = "ConceptTypes";
		$TYPE = "CONCEPT";
	}
	
	if ($file eq "CivEffects/CIV4CivEffectsInfos.xml")
	{
		$basename = "CivEffect";
		$enum = "CivEffectTypes";
		$TYPE = "CIV_EFFECT";
	}
	
	if ($file eq "Civilizations/CIV4UnitArtStyleTypeInfos.xml")
	{
		$enum = "UnitArtStyleTypes";
		$TYPE = "UNIT_ARTSTYLE";
	}
	
	return ($basename, $enum, $TYPE);
}

sub getNoType
{
	my $type = shift;
	
	return "NO_FATHER_POINT_TYPE" if $type eq "FATHER_POINT";
	
	return "NO_" . $type;
}

sub getNumFunction
{
	my $basename = shift;

	return "m_paCivEffectInfo.size()"   if $basename eq "CivEffect";
	return "m_paDomainInfo.size()"      if $basename eq "Domain";
	return "m_paUnitAIInfos.size()"     if $basename eq "UnitAI";
	return "GC.getNumWorldInfos()"      if $basename eq "WorldSize";
	return "m_paYieldInfo.size()"       if $basename eq "Yield";
	
	return "GC.getNum" . $basename . "Infos()";
}

sub getInfo
{
	my $basename = shift;

	return "GC.getWorldInfo" if $basename eq "WorldSize";
	
	return "GC.get" . $basename . "Info";
}

sub isTwoLevelFile
{
	my $file = shift;
	
	return 1 if $file eq "CivEffects/CIV4CivEffectsInfos.xml";
	return 1 if $file eq "Events/CIV4AchieveInfos.xml";
	return 1 if $file eq "Terrain/CIV4YieldCategoryInfos.xml";
	
	return 0;
}

sub getEnumFiles
{
	my @list = ();
	
	push(@list, "BasicInfos/CIV4BasicInfos.xml");
	push(@list, "BasicInfos/CIV4DomainInfos.xml");
	push(@list, "BasicInfos/CIV4FatherCategoryInfos.xml");
	push(@list, "BasicInfos/CIV4InvisibleInfos.xml");
	push(@list, "BasicInfos/CIV4UnitAIInfos.xml");
	push(@list, "BasicInfos/CIV4UnitCombatInfos.xml");
	
	push(@list, "Buildings/CIV4BuildingClassInfos.xml");
	push(@list, "Buildings/CIV4BuildingInfos.xml");
	push(@list, "Buildings/CIV4SpecialBuildingInfos.xml");
	
	push(@list, "CivEffects/CIV4CivEffectsInfos.xml");
	
	push(@list, "Civilizations/CIV4AlarmInfos.xml");
	push(@list, "Civilizations/CIV4CivilizationInfos.xml");
	push(@list, "Civilizations/CIV4LeaderHeadInfos.xml");
	push(@list, "Civilizations/CIV4TraitInfos.xml");
	push(@list, "Civilizations/CIV4UnitArtStyleTypeInfos.xml");
	
	push(@list, "Events/CIV4AchieveInfos.xml");
	push(@list, "Events/CIV4EventInfos.xml");
	push(@list, "Events/CIV4EventTriggerInfos.xml");
	
	push(@list, "GameInfo/CIV4CivicInfos.xml");
	push(@list, "GameInfo/CIV4CivicOptionInfos.xml");
	push(@list, "GameInfo/CIV4ClimateInfo.xml");
	push(@list, "GameInfo/CIV4CultureLevelInfo.xml");
	push(@list, "GameInfo/CIV4DiplomacyInfos.xml");
	push(@list, "GameInfo/CIV4EmphasizeInfo.xml");
	push(@list, "GameInfo/CIV4EraInfos.xml");
	push(@list, "GameInfo/CIV4EuropeInfo.xml");
	push(@list, "GameInfo/CIV4FatherInfos.xml");
	push(@list, "GameInfo/CIV4FatherPointInfos.xml");
	push(@list, "GameInfo/CIV4GameOptionInfos.xml");
	push(@list, "GameInfo/CIV4GameSpeedInfo.xml");
	push(@list, "GameInfo/CIV4GoodyInfo.xml");
	push(@list, "GameInfo/CIV4HandicapInfo.xml");
	push(@list, "GameInfo/CIV4HurryInfo.xml");
	push(@list, "GameInfo/CIV4PlayerOptionInfos.xml");
	push(@list, "GameInfo/CIV4SeaLevelInfo.xml");
	push(@list, "GameInfo/CIV4VictoryInfo.xml");
	push(@list, "GameInfo/CIV4WorldInfo.xml");
	
	push(@list, "Misc/CIV4EffectInfos.xml");
	push(@list, "Misc/CIV4RouteInfos.xml");
	
	push(@list, "Terrain/CIV4BonusInfos.xml");
	push(@list, "Terrain/CIV4FeatureInfos.xml");
	push(@list, "Terrain/CIV4ImprovementInfos.xml");
	push(@list, "Terrain/CIV4TerrainInfos.xml");
	push(@list, "Terrain/CIV4YieldCategoryInfos.xml");
	push(@list, "Terrain/CIV4YieldInfos.xml");
	
	push(@list, "Units/CIV4AutomateInfos.xml");
	push(@list, "Units/CIV4BuildInfos.xml");
	push(@list, "Units/CIV4CommandInfos.xml");
	push(@list, "Units/CIV4ControlInfos.xml");
	push(@list, "Units/CIV4MissionInfos.xml");
	push(@list, "Units/CIV4ProfessionInfos.xml");
	push(@list, "Units/CIV4PromotionInfos.xml");
	push(@list, "Units/CIV4UnitClassInfos.xml");
	push(@list, "Units/CIV4UnitInfos.xml");
	
	return @list;
}

sub isDllExport
{
	my $type = shift;
	
	return 1 if $type eq "AlarmTypes";
	return 1 if $type eq "AutomateTypes";
	return 1 if $type eq "BonusTypes";
	return 1 if $type eq "BuildingClassTypes";
	return 1 if $type eq "BuildingTypes";
	return 1 if $type eq "BuildTypes";
	return 1 if $type eq "CivicTypes";
	return 1 if $type eq "CivicOptionTypes";
	return 1 if $type eq "CivilizationTypes";
	return 1 if $type eq "ClimateTypes";
	return 1 if $type eq "ConceptTypes";
	return 1 if $type eq "ControlTypes";
	return 1 if $type eq "CultureLevelTypes";
	return 1 if $type eq "DomainTypes";
	return 1 if $type eq "EffectTypes";
	return 1 if $type eq "EmphasizeTypes";
	return 1 if $type eq "EraTypes";
	return 1 if $type eq "EventTriggerTypes";
	return 1 if $type eq "EventTypes";
	return 1 if $type eq "EuropeTypes";
	return 1 if $type eq "FatherCategoryTypes";
	return 1 if $type eq "FatherPointTypes";
	return 1 if $type eq "FatherTypes";
	return 1 if $type eq "FeatureTypes";
	return 1 if $type eq "GameOptionTypes";
	return 1 if $type eq "GameSpeedTypes";
	return 1 if $type eq "GoodyTypes";
	return 1 if $type eq "HandicapTypes";
	return 1 if $type eq "HurryTypes";
	return 1 if $type eq "ImprovementTypes";
	return 1 if $type eq "InvisibleTypes";
	return 1 if $type eq "LeaderHeadTypes";
	return 1 if $type eq "MissionTypes";
	return 1 if $type eq "PlayerOptionTypes";
	return 1 if $type eq "ProfessionTypes";
	return 1 if $type eq "PromotionTypes";
	return 1 if $type eq "RouteTypes";
	return 1 if $type eq "SeaLevelTypes";
	return 1 if $type eq "SpecialBuildingTypes";
	return 1 if $type eq "TerrainTypes";
	return 1 if $type eq "TraitTypes";
	return 1 if $type eq "UnitAITypes";
	return 1 if $type eq "UnitClassTypes";
	return 1 if $type eq "UnitCombatTypes";
	return 1 if $type eq "UnitTypes";
	return 1 if $type eq "VictoryTypes";
	return 1 if $type eq "WorldSizeTypes";
	return 1 if $type eq "YieldTypes";


	return 0
}

sub updateAutoFile
{
	my $FILE_TMP = shift;
	my $FILE = substr($FILE_TMP, 0, -4);

	die "Missing .tmp extension on temp auto file.\n" unless substr($FILE_TMP, -4) eq ".tmp";

	if (not -e $FILE or compare($FILE, $FILE_TMP) != 0)
	{
		# file is outdated or missing. Move the temp file
		# copying forces a complete recompile. It really should only be done if something changed.
		copy($FILE_TMP, $FILE);
	}
}
