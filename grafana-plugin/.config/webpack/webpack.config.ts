import type { Configuration, ExternalItemFunctionData } from 'webpack';
import path from 'path';
import CopyWebpackPlugin from 'copy-webpack-plugin';
import ForkTsCheckerWebpackPlugin from 'fork-ts-checker-webpack-plugin';

const SOURCE_DIR = path.resolve(process.cwd(), 'src');
const DIST_DIR = path.resolve(process.cwd(), 'dist');

const config = async (env: { production?: boolean; development?: boolean }): Promise<Configuration> => {
  const isProduction = !!env.production;

  return {
    mode: isProduction ? 'production' : 'development',
    devtool: isProduction ? 'source-map' : 'eval-source-map',

    entry: {
      module: path.join(SOURCE_DIR, 'module.ts'),
    },

    output: {
      path: DIST_DIR,
      filename: '[name].js',
      library: {
        type: 'amd',
      },
      publicPath: '/',
      clean: true,
    },

    externals: [
      'lodash',
      'react',
      'react-dom',
      '@grafana/data',
      '@grafana/runtime',
      '@grafana/schema',
      '@grafana/ui',
      function (
        { request }: ExternalItemFunctionData,
        callback: (err?: Error | null, result?: string) => void
      ) {
        const prefix = 'grafana/';
        if (request?.startsWith(prefix)) {
          return callback(undefined, request.substring(prefix.length));
        }
        callback();
      },
    ],

    plugins: [
      new CopyWebpackPlugin({
        patterns: [
          { from: 'README.md', to: '.', noErrorOnMissing: true },
          { from: 'src/plugin.json', to: '.' },
          { from: 'CHANGELOG.md', to: '.', noErrorOnMissing: true },
          { from: 'LICENSE', to: '.', noErrorOnMissing: true },
          { from: 'img', to: 'img', noErrorOnMissing: true },
        ],
      }),
      new ForkTsCheckerWebpackPlugin({
        async: Boolean(env.development),
        typescript: {
          configFile: path.join(process.cwd(), 'tsconfig.json'),
        },
      }),
    ],

    resolve: {
      extensions: ['.ts', '.tsx', '.js', '.jsx'],
      unsafeCache: true,
    },

    module: {
      rules: [
        {
          test: /\.[tj]sx?$/,
          exclude: /node_modules/,
          use: {
            loader: 'swc-loader',
            options: {
              jsc: {
                parser: {
                  syntax: 'typescript',
                  tsx: true,
                  decorators: false,
                  dynamicImport: true,
                },
                target: 'es2020',
                transform: {
                  react: {
                    runtime: 'automatic',
                  },
                },
              },
            },
          },
        },
        {
          test: /\.css$/,
          use: ['style-loader', 'css-loader'],
        },
        {
          test: /\.s[ac]ss$/,
          use: ['style-loader', 'css-loader', 'sass-loader'],
        },
        {
          test: /\.(png|jpe?g|gif|svg)$/,
          type: 'asset/resource',
          generator: {
            publicPath: 'public/plugins/fangorn-sentinel-app/',
            outputPath: 'img/',
          },
        },
        {
          test: /\.(woff|woff2|eot|ttf|otf)$/,
          type: 'asset/resource',
          generator: {
            publicPath: 'public/plugins/fangorn-sentinel-app/',
            outputPath: 'fonts/',
          },
        },
      ],
    },
  };
};

export default config;
