#!/usr/bin/env bash

# Post Build Script

# set -e # Exit immediately if a command exits with a non-zero status (failure)
# don't set here. This causes the script to fail on this line: anyFailedTests=$(grep 'result=\"Failed\"' $pathOfTestResults)

echo "**************************************************************************************************"
echo "Post Build Script"
echo "**************************************************************************************************"


##################################################
# Run Unit Tests
##################################################

# Run all NUnit test projects that have "UnitTest" in the name.
# The script will build, run, and display the results in the build logs.

echo 
echo "**************************************************************************************************"
echo "Run Unit Tests"
echo "**************************************************************************************************"
echo "Working directory:" $APPCENTER_SOURCE_DIRECTORY
echo "**************************************************************************************************"
echo 

echo "Found NUnit test projects:"
find $APPCENTER_SOURCE_DIRECTORY -regex '.*UnitTest.*\.csproj' -exec echo {} \;
echo

echo "Building NUnit test projects:"
find $APPCENTER_SOURCE_DIRECTORY -regex '.*UnitTest.*\.csproj' -exec msbuild {} \;
echo

echo "Compiled projects to run NUnit tests:"
find $APPCENTER_SOURCE_DIRECTORY -regex '.*bin.*UnitTest.*\.dll' -exec echo {} \;
echo

echo "Running NUnit tests:"
find $APPCENTER_SOURCE_DIRECTORY -regex '.*bin.*UnitTest.*\.dll' -exec nunit3-console {} \;
echo

echo "Find NUnit test results:"
pathOfTestResults=$(find $APPCENTER_SOURCE_DIRECTORY -name 'TestResult.xml')
echo $pathOfTestResults
echo

# Check if file path variable is empty
if [ -z "$pathOfTestResults" ]
then
    echo "NUnit test result file not found. Exiting."
    exit 1 # exit with unspecified error code. Should be obvious why we can't continue the script
else
    echo "NUnit test result file found"
fi

# echo "Output NUnit test results:"
# cat $pathOfTestResults
# echo
# echo

echo "Look for failing tests:"
anyFailedTests=$(grep 'result=\"Failed\"' $pathOfTestResults)

if [ -z "$anyFailedTests" ]
then
    echo "All unit tests passed" 
else
    echo "One or more unit tests failed" 
    echo $anyFailedTests
    exit 1
fi




##################################################
# Run UI Tests in Test Cloud
##################################################

set -e # Exit immediately if a command exits with a non-zero status (failure)

# variables
shouldRunUITestsInTestCloud=$RunUITestsInTestCloud # yes/no flag
appCenterLoginApiToken=$AppCenterLoginForAutomatedUITests # these all come from the build environment variables
appName="tomso/Pickster-2"
deviceSetName=$UITestDeviceSet
testSeriesName="smoke-tests"

echo 
echo "**************************************************************************************************"
echo "Run Xamarin.UITests in Test Cloud"
echo "**************************************************************************************************"
echo "Source directory: $APPCENTER_SOURCE_DIRECTORY"
echo "Output directory: $APPCENTER_OUTPUT_DIRECTORY"
echo "    Run UI Tests: $RunUITestsInTestCloud"
echo "        App Name: $appName"
echo "      Device Set: $deviceSetName"
echo "     Test Series: $testSeriesName"
echo 

if [ $shouldRunUITestsInTestCloud != "yes" ]
then
    echo "> Should run UI tests in Test Cloud:" $shouldRunUITestsInTestCloud
else
    echo "> Build UI Test project"
    echo "Command: find $APPCENTER_SOURCE_DIRECTORY -regex '.*UITest.*\.csproj' -exec msbuild {} /t:Build \;"
    echo

    # using msbuild, build the "Build" target
    find $APPCENTER_SOURCE_DIRECTORY -regex '.*UITest.*\.csproj' -exec msbuild {} /t:Build \;

    echo
    echo "> UI test command to run:"
    echo "appcenter test run uitest" 
    echo "--app $appName" 
    echo "--devices $deviceSetName"
    echo "--app-path $APPCENTER_OUTPUT_DIRECTORY/*.ipa"
    echo "--test-series $testSeriesName"
    echo "--locale \"en_US\"" 
    echo "--build-dir $APPCENTER_SOURCE_DIRECTORY/Pickster/Pickster.UITests/bin/Debug"
    echo "--uitest-tools-dir $APPCENTER_SOURCE_DIRECTORY/Pickster/packages/Xamarin.UITest.*/tools"
    echo "--token $appCenterLoginApiToken"

    echo ""
    echo "> Run UI test command"
    # Note: must put a space after each parameter/value pair
    appcenter test run uitest \
    --app $appName \
    --devices $deviceSetName \
    --app-path $APPCENTER_OUTPUT_DIRECTORY/*.ipa \
    --test-series $testSeriesName \
    --locale "en_US" \
    --build-dir $APPCENTER_SOURCE_DIRECTORY/Pickster/Pickster.UITests/bin/Debug \
    --uitest-tools-dir $APPCENTER_SOURCE_DIRECTORY/Pickster/packages/Xamarin.UITest.*/tools \
    --token $appCenterLoginApiToken 
fi

echo ""
echo "**************************************************************************************************"
echo "Post Build Script complete"
echo "**************************************************************************************************"
