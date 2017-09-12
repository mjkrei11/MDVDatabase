using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Text;
using Microsoft.Data.Tools.Schema.Sql.UnitTesting;
using Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace MDVTest
{
    [TestClass()]
    public class SqlServerUnitTest1 : SqlDatabaseTestClass
    {

        public SqlServerUnitTest1()
        {
            InitializeComponent();
        }

        [TestInitialize()]
        public void TestInitialize()
        {
            base.InitializeTest();
        }
        [TestCleanup()]
        public void TestCleanup()
        {
            base.CleanupTest();
        }

        #region Designer support code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestAction dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction;
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(SqlServerUnitTest1));
            Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.InconclusiveCondition inconclusiveCondition1;
            this.dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestActions();
            dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.SqlDatabaseTestAction();
            inconclusiveCondition1 = new Microsoft.Data.Tools.Schema.Sql.UnitTesting.Conditions.InconclusiveCondition();
            // 
            // dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction
            // 
            dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction.Conditions.Add(inconclusiveCondition1);
            resources.ApplyResources(dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction, "dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction");
            // 
            // inconclusiveCondition1
            // 
            inconclusiveCondition1.Enabled = true;
            inconclusiveCondition1.Name = "inconclusiveCondition1";
            // 
            // dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData
            // 
            this.dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData.PosttestAction = null;
            this.dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData.PretestAction = null;
            this.dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData.TestAction = dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest_TestAction;
        }

        #endregion


        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        #endregion

        [TestMethod()]
        public void dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTest()
        {
            SqlDatabaseTestActions testActions = this.dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData;
            // Execute the pre-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PretestAction != null), "Executing pre-test script...");
            SqlExecutionResult[] pretestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PretestAction);
            try
            {
                // Execute the test script
                // 
                System.Diagnostics.Trace.WriteLineIf((testActions.TestAction != null), "Executing test script...");
                SqlExecutionResult[] testResults = TestService.Execute(this.ExecutionContext, this.PrivilegedContext, testActions.TestAction);
            }
            finally
            {
                // Execute the post-test script
                // 
                System.Diagnostics.Trace.WriteLineIf((testActions.PosttestAction != null), "Executing post-test script...");
                SqlExecutionResult[] posttestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PosttestAction);
            }
        }
        private SqlDatabaseTestActions dbo_sp_ssrs_TCO_QuarterlyTPS_RepTrendTestData;
    }
}
