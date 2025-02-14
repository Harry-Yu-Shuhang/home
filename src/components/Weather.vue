<template>
  <div class="weather" v-if="weatherData?.adCode?.city && weatherData?.weather?.weather">
    <span>{{ weatherData.adCode.city }}&nbsp;</span>
    <span>{{ weatherData.weather.weather }}&nbsp;</span>
    <span>{{ weatherData.weather.temperature }}℃</span>
    <span class="sm-hidden">
      &nbsp;{{ weatherData.weather.winddirection?.endsWith("风") ? weatherData.weather.winddirection : weatherData.weather.winddirection + "风" }}&nbsp;
    </span>
    <span class="sm-hidden">{{ weatherData.weather.windpower }}&nbsp;级</span>
  </div>
  <div class="weather" v-else>
    <span>天气数据获取失败</span>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, h } from "vue";
import { getAdcode, getWeather, getOtherWeather } from "@/api";
import { ElMessage } from "element-plus";
import { WarningFilled } from "@element-plus/icons-vue";

// 高德开发者 Key
const mainKey = import.meta.env.VITE_WEATHER_KEY;

// 天气数据
const weatherData = reactive({
  adCode: { city: null, adcode: null },
  weather: { weather: null, temperature: null, winddirection: null, windpower: null },
});

// 计算平均温度
const getTemperature = (min, max) => {
  if (isNaN(min) || isNaN(max)) {
    console.error("温度数据无效");
    return "未知";
  }
  return Math.round((Number(min) + Number(max)) / 2);
};

// 备用天气数据获取
const fetchWeatherFromOtherSource = async () => {
  const result = await getOtherWeather();
  const data = result.result;
  weatherData.adCode.city = data.city.City || "未知地区";
  weatherData.weather = {
    weather: data.condition.day_weather,
    temperature: getTemperature(data.condition.min_degree, data.condition.max_degree),
    winddirection: data.condition.day_wind_direction,
    windpower: data.condition.day_wind_power,
  };
};

// 通过高德 API 获取天气
const fetchWeatherFromAMap = async () => {
  const adCode = await getAdcode(mainKey);
  if (adCode.infocode !== "10000") throw new Error("地区查询失败");
  
  weatherData.adCode.city = adCode.city;
  weatherData.adCode.adcode = adCode.adcode;
  
  if (!weatherData.adCode.adcode) throw new Error("无法获取天气数据，缺少 adcode");

  const result = await getWeather(mainKey, weatherData.adCode.adcode);
  const liveWeather = result.lives[0];
  weatherData.weather = {
    weather: liveWeather.weather,
    temperature: liveWeather.temperature,
    winddirection: liveWeather.winddirection,
    windpower: liveWeather.windpower,
  };
};

// 获取天气数据
const getWeatherData = async () => {
  try {
    if (!mainKey) {
      console.log("未配置 API Key，使用备用天气接口");
      await fetchWeatherFromOtherSource();
    } else {
      await fetchWeatherFromAMap();
    }
  } catch (error) {
    console.error("天气信息获取失败:", error);
    onError("天气信息获取失败");
  }
};

// 统一错误处理
const onError = (message) => {
  ElMessage({
    message,
    type: "error",
    icon: h(WarningFilled, { style: "color: red;" }),
  });
};

onMounted(() => {
  getWeatherData();
});
</script>