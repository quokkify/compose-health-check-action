export default {
  name: "Compose Health Check Action",
  output: "./allure-report",
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
