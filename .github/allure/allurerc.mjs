export default {
  name: "Compose Health Check Action",
  output: "./allure-report",
  historyPath: "./allure-history/history.jsonl",
  historyLimit: 20,
  plugins: {
    awesome: {
      options: {
        reportName: "Compose Health Check Action test report",
        singleFile: false,
        reportLanguage: "en",
        groupBy: ["epic", "feature", "story"],
      },
    },
  },
};
