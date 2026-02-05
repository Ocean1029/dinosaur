import { createLogger } from "../utils/logger.js";

const logger = createLogger("nfc-service");

interface NFCReadData {
  nfcId: string;
  tagType?: string;
  timestamp?: string;
  deviceInfo?: {
    platform?: string;
    model?: string;
    osVersion?: string;
  };
}

interface NFCReadParams {
  traceId: string;
  data: NFCReadData;
}

const handleNFCRead = async (params: NFCReadParams): Promise<{ success: boolean; message: string; data?: NFCReadData }> => {
  const { data, traceId } = params;

  // 在终端显示 NFC 读取结果
  logger.info("═══════════════════════════════════════════════════════");
  logger.info("📱 NFC 感應事件");
  logger.info("═══════════════════════════════════════════════════════");
  logger.info(`NFC ID: ${data.nfcId}`);
  
  if (data.tagType) {
    logger.info(`標籤類型: ${data.tagType}`);
  }
  
  if (data.timestamp) {
    logger.info(`時間戳記: ${data.timestamp}`);
  } else {
    logger.info(`時間戳記: ${new Date().toISOString()}`);
  }
  
  if (data.deviceInfo) {
    logger.info("裝置資訊:");
    if (data.deviceInfo.platform) {
      logger.info(`  平台: ${data.deviceInfo.platform}`);
    }
    if (data.deviceInfo.model) {
      logger.info(`  型號: ${data.deviceInfo.model}`);
    }
    if (data.deviceInfo.osVersion) {
      logger.info(`  OS 版本: ${data.deviceInfo.osVersion}`);
    }
  }
  
  logger.info(`追蹤 ID: ${traceId}`);
  logger.info("═══════════════════════════════════════════════════════");

  return {
    success: true,
    message: `NFC ID ${data.nfcId} 已成功接收並顯示在終端`,
    data
  };
};

export const nfcService = {
  handleNFCRead
};

