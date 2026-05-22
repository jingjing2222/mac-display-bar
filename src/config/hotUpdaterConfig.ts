declare const process: {
  env: {
    HOT_UPDATER_BASE_URL: string;
  };
};

export const hotUpdaterBaseURL = process.env.HOT_UPDATER_BASE_URL;
