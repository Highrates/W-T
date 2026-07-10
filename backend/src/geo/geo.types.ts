export interface GeoSuggestItemDto {
  title: string;
  subtitle: string;
  latitude: number;
  longitude: number;
  cityId?: string;
}

export interface GeoReverseResultDto {
  title: string;
  address: string;
  latitude: number;
  longitude: number;
  cityId?: string;
}

export interface YandexSuggestResponse {
  results?: Array<{
    title?: { text?: string };
    subtitle?: { text?: string };
    tags?: string[];
  }>;
}

export interface YandexGeocoderResponse {
  response?: {
    GeoObjectCollection?: {
      featureMember?: Array<{
        GeoObject?: {
          name?: string;
          description?: string;
          metaDataProperty?: {
            GeocoderMetaData?: {
              text?: string;
              Address?: {
                formatted?: string;
                Components?: Array<{ kind?: string; name?: string }>;
              };
            };
          };
          Point?: { pos?: string };
        };
      }>;
    };
  };
}
