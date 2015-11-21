package com.example.android.sunshine.app;

/**
 * Created by hedong on 15/11/12.
 */

import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.text.format.Time;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ListView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
/**
 * A placeholder fragment containing a simple view.
 */
public class ForecastFragment extends Fragment {
    ArrayAdapter<String> mForcastAdapter;
    String[] data = {
            "clear 2015-11-09",
            "clear 2015-11-10",
            "clear 2015-11-11",
            "clear 2015-11-12",
            "clear 2015-11-13",
            "clear 2015-11-14",
    };
    List<String> week_forcast = new ArrayList<String>(Arrays.asList(data));

    public ForecastFragment() {
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        //add this line in order for this fragment to handle menu events
        setHasOptionsMenu(true);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        switch (id) {
            case R.id.action_refresh:
                FeathWeatherTask feathWeatherTask = new FeathWeatherTask();
                feathWeatherTask.execute("94043");
                break;
            default:
                break;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onCreateOptionsMenu(Menu menu, MenuInflater inflater) {
        inflater.inflate(R.menu.forecastfragment, menu);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        mForcastAdapter = new ArrayAdapter<String>(
                getActivity(),
                R.layout.list_item_forecast,
                R.id.list_item_forecast_textview,
                week_forcast);

        View rootView = inflater.inflate(R.layout.fragment_main, container, false);
        ListView listView = (ListView) rootView.findViewById(R.id.listview_forecast);
        listView.setAdapter(mForcastAdapter);

        return rootView;
    }


    public class FeathWeatherTask extends AsyncTask<String, Void, String[]> {
        /*The Date/time conversion code is going to be moved outside the asynctask later,
         *so for convenience we're breaking it out into it's own method now
         */
        private String getReadableDateString(long time) {
            //Because the API returns a unix timestamp
            //it must be converted to millisenconds in order to be converted to valid date
            SimpleDateFormat shortenedDateFormat = new SimpleDateFormat("EEE MMM dd");
            return shortenedDateFormat.format(time);
        }


        /**
         * Prepare the weather high/lows for presentation
         */
        private String formatHighLows(double high, double low) {
            long roundedHigh = Math.round(high);
            long roundedLow = Math.round(low);

            String highLowStr = roundedHigh + "/" + roundedLow;
            return highLowStr;
        }

        /**
         * Take the String representing the complete forecast in JSON
         * Format and pull out the data we need to construct the Strings
         * needed for the wireframes
         */
        private String[] getWeatherDataFromJson(String forecastJsonStr, int numdays)
                throws JSONException {
            //these are the name of the JSON onjects that need to be extracted
            final String OWM_LIST = "list";
            final String OWM_WEATHER = "weather";
            final String OWM_TEMPERATURE = "temp";
            final String OWM_MAX = "max";
            final String OWM_MIN = "min";
            final String OWM_DESCRIPTION = "main";

            JSONObject forecastJson = new JSONObject(forecastJsonStr);
            JSONArray weatherArray = forecastJson.getJSONArray(OWM_LIST);

            //OWM returns daily forecasts based upon the local time of the city
            //that is being asked for, which means that we need to konw the GMT
            //offset to translate this data proprely

            //Since this data is also sent in-order and the first day is always
            //the current day, we're going to take advantage of that to get a
            //nice normalized UTC date for all of our weather
            Time dayTime = new Time();
            dayTime.setToNow();

            //we start at the day return by local time, Otherwise this is a mess
            int julianStartDay = Time.getJulianDay(System.currentTimeMillis(), dayTime.gmtoff);

            //now we work exclusively in UTC
            dayTime = new Time();

            String[] resultStrs = new String[numdays];
            for (int i = 0; i < weatherArray.length(); i++) {
                //for now, using the format "Day, description, high/low"
                String day;
                String description;
                String highAndLow;

                //Get the JSON object representing the day
                JSONObject dayFoercast = weatherArray.getJSONObject(i);

                //the date/time is return as a long. we need to convert that
                //into something human-readable
                long dateTime;
                dateTime = dayTime.setJulianDay(julianStartDay + i);
                day = getReadableDateString(dateTime);
                //description is in a child array called "weather"
                JSONObject weatherObject = dayFoercast.getJSONArray(OWM_WEATHER).getJSONObject(0);
                description = weatherObject.getString(OWM_DESCRIPTION);

                //tempreatures are in a child object called "temp"
                JSONObject tempreatureObject = dayFoercast.getJSONObject(OWM_TEMPERATURE);
                double high = tempreatureObject.getDouble(OWM_MAX);
                double low = tempreatureObject.getDouble(OWM_MIN);

                highAndLow = formatHighLows(high, low);
                resultStrs[i] = day + " - " + description + " - " + highAndLow;
            }
            for (String s : resultStrs) {
                Log.v("hedong", "Forecast entry: " + s);
            }
            return  resultStrs;
        }

        @Override
        protected String[] doInBackground(String... params) {

            //if there's no zip code, there's nothing to look up.
            //verify size of params
            if(params.length == 0) {
                return null;
            }
            //These two need to be declared outsite the try/catch
            //so that they can be closed in the finally block
            HttpURLConnection urlConnection = null;
            BufferedReader reader = null;

            //will contain the raw JSON response as a String
            String forecastJsonStr = null;

            String format = "json";
            String units = "mearic";
            int numDays = 7;
            try {
                // Construct the URL for the OpenWeatherMap query
                // Possible parameters are avaiable at OWM's forecast API page, at
                // http://openweathermap.org/API#forecast
                final String FORECAST_BASE_URL =
                        "http://api.openweathermap.org/data/2.5/forecast/daily?";
                final String QUERY_PARAM = "q";
                final String FORMAT_PARAM = "mode";
                final String UNITS_PARAM = "units";
                final String DAYS_PARAM = "cnt";
                final String APPID_PARAM = "APPID";

                Uri builtUri = Uri.parse(FORECAST_BASE_URL).buildUpon()
                        .appendQueryParameter(QUERY_PARAM, params[0])
                        .appendQueryParameter(FORMAT_PARAM, format)
                        .appendQueryParameter(UNITS_PARAM, units)
                        .appendQueryParameter(DAYS_PARAM, Integer.toString(numDays))
                        .appendQueryParameter(APPID_PARAM, BuildConfig.OPEN_WEATHER_MAP_API_KEY)
                        .build();

                URL url = new URL(builtUri.toString());

                //create the request to OpenWeatherMap, and open the connection
                urlConnection = (HttpURLConnection) url.openConnection();
                urlConnection.setRequestMethod("GET");
                urlConnection.connect();

                //read the input stream into a String
                InputStream inputStream = urlConnection.getInputStream();
                StringBuffer buffer = new StringBuffer();
                if (inputStream == null) {
                    //nothing to do
                    return null;
                }
                reader = new BufferedReader(new InputStreamReader(inputStream));

                String line;
                while ((line = reader.readLine()) != null) {
                    //since it's JSON, adding a newline isn't necessary(it won't affect parsing)
                    //but it does make debugging a lot easier if you print out the completed
                    //buffer for debuging
                    buffer.append(line + "\n");
                }

                if (buffer.length() == 0) {
                    //stream was empty,.No point in parsing
                    return null;
                }
                forecastJsonStr = buffer.toString();
            } catch (IOException e) {
                Log.e("ForecastFragment", "Error", e);
                return null;
            } finally {
                if (urlConnection != null) {
                    urlConnection.disconnect();
                }

                if (reader != null) {
                    try {
                        reader.close();
                    } catch (final IOException e) {
                        Log.e("ForecastFragment", "Error", e);
                    }
                }
            }
            Log.d("hedong", "jsonstr=" + forecastJsonStr);
            try {
                return getWeatherDataFromJson(forecastJsonStr, numDays);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            return null;
        }

        @Override
        protected void onPostExecute(String[] result) {
            if (null != result) {
                mForcastAdapter.clear();
                for (String dayForecastStr : result) {
                    mForcastAdapter.add(dayForecastStr);
                }
            }
        }
    }
}
