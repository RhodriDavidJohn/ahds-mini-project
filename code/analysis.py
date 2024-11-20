
print("(INFO): Importing packages")
import pandas as pd
import os
from joblib import Parallel, delayed
from plotly.subplots import make_subplots
import plotly.graph_objs as go

from utils.model import train_model, plot_topic_trends


# set some environment settings
os.environ["TOKENIZERS_PARALLELISM"] = "true"


# define the input and output filepaths
data_dir = "data/clean"
output_path = "results"


print("(INFO): Loading cleaned data")
# load the three tsv files
title_df = pd.read_csv(os.path.join(data_dir, "title_data.tsv"),
                       sep='\t')
abstract_df = pd.read_csv(os.path.join(data_dir, "abstract_data.tsv"),
                          sep='\t')
keywords_df = pd.read_csv(os.path.join(data_dir, "keyword_mesh_data.tsv"),
                          sep='\t')


def dynamic_topic_modelling(
        df,
        column: str,
        title: str
    ):
    
    # get a list of dates and text to analyse
    dates = df["date"].to_list()
    text = df[column].to_list()
    
    # fit the dtm model and plot the reults
    model = train_model(text)
    fig = plot_topic_trends(model, text, dates, title, output_path)
    
    return fig


# define the list of parameters to be passed to the dtm analysis
data = [title_df, abstract_df, keywords_df]
text_columns = ["article_title", "abstract", "keywords"]
titles = ["Title", "Abstract", "Keywords-MESH"]

params = zip(data, text_columns, titles)


print("(INFO): Beginning analysis")
# conduct the 3 dtm analyses in parallel
dtm_figs = Parallel(n_jobs=3)(delayed(dynamic_topic_modelling)(param[0], param[1], param[2]) for param in params)
print(len(dtm_figs[0].data))
fig = make_subplots(rows=3, cols=1)
for trace in dtm_figs[0].data:
    fig.add_trace(trace, row=1, col=1)
for trace in dtm_figs[1].data:
    fig.add_trace(trace, row=2, col=1)
for trace in dtm_figs[2].data:
    fig.add_trace(trace, row=3, col=1)
fig.show()
fig.write_image(os.path.join(output_path, 'topics_over_time.png'))

print("(INFO): Finished analysis")
